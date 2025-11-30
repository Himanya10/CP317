//
//  FoodRecognitionService.swift
//  CP317-Application
//

import Foundation
import UIKit
import SwiftUI

class FoodRecognitionService {
    static let shared = FoodRecognitionService()
    
    private let apiKey = Config.geminiAPIKey
    // Using the stable version to avoid 404 errors
    private let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private init() {}
    
    // MARK: - Main Food Analysis Function
    
    func analyzeFood(image: UIImage, userModifications: String? = nil) async throws -> FoodAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        let prompt = buildConsolidatedGeminiPrompt(userModifications: userModifications)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]
        
        guard let url = URL(string: "\(geminiEndpoint)?key=\(apiKey)") else {
            throw FoodRecognitionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodRecognitionError.apiError
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorBody = String(data: data, encoding: .utf8) {
                 print("DEBUG: Gemini API Error \(httpResponse.statusCode). Body: \(errorBody)")
            }
            throw FoodRecognitionError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try parseGeminiResponse(data)
    }
    
    // MARK: - Prompt Engineering
    
    private func buildConsolidatedGeminiPrompt(userModifications: String?) -> String {
        var prompt = """
        You are a nutrition expert AI. Analyze the provided image of food.
        1. Identify the food item(s).
        2. Estimate portion sizes.
        3. Calculate total calories.
        4. Provide macronutrients.
        
        """
        
        if let modifications = userModifications, !modifications.isEmpty {
            prompt += """
            User's notes to consider:
            \(modifications)
            
            """
        }
        
        prompt += """
        
        IMPORTANT JSON INSTRUCTIONS:
        - Return ONLY valid JSON.
        - Do NOT include markdown code blocks (like ```json).
        - 'calories' must be a NUMBER (Integer), do NOT include 'kcal'.
        - 'protein', 'carbs', 'fat', 'fiber' must be NUMBERS (Double/Int), do NOT include 'g'.
        
        Return JSON in this EXACT format:
        {
          "foodName": "Food Name",
          "description": "Short description of meal",
          "portionSize": "e.g. 1 bowl",
          "calories": 500,
          "protein": 25,
          "carbs": 40,
          "fat": 20,
          "fiber": 5,
          "ingredients": ["item1", "item2"],
          "confidence": 0.95,
          "reasoning": "Reasoning for estimate...",
          "modifications": "User notes included...",
          "servingSize": "1 serving"
        }
        """
        
        return prompt
    }
    
    // MARK: - Parsing Logic
    
    private func parseGeminiResponse(_ data: Data) throws -> FoodAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            print("DEBUG: No candidates found in response.")
            throw FoodRecognitionError.parsingError
        }
        
        // Safety Check: Did the AI refuse to answer?
        if let finishReason = firstCandidate["finishReason"] as? String, finishReason != "STOP" {
            print("DEBUG: AI stopped generating. Reason: \(finishReason)")
            if finishReason == "SAFETY" {
                throw FoodRecognitionError.safetyBlocked
            }
        }
        
        guard let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let rawText = parts.first?["text"] as? String else {
            print("DEBUG: Failed to extract text from candidate.")
            throw FoodRecognitionError.parsingError
        }
        
        print("DEBUG: Raw AI Response: \(rawText)")

        // Robust Regex Extraction
        let pattern = "(?s)\\{(.*)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: rawText, options: [], range: NSRange(location: 0, length: rawText.utf16.count)) else {
            print("DEBUG: No JSON object found in response.")
            throw FoodRecognitionError.parsingError
        }
        
        var jsonString = (rawText as NSString).substring(with: match.range)
        // Clean up markdown just in case
        jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FoodRecognitionError.parsingError
        }

        do {
            let result = try JSONDecoder().decode(FoodAnalysisResult.self, from: jsonData)
            return result
        } catch {
            print("DEBUG: JSON Decode Failed: \(error)")
            throw FoodRecognitionError.parsingError
        }
    }
}

// MARK: - Models

// Placeholder model (no longer used for Vision API, but kept for type safety if referenced elsewhere)
struct VisionResult {
    let text: String
    let labels: [String]
}

struct FoodAnalysisResult: Codable, Equatable {
    let foodName: String
    let description: String
    let portionSize: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    let ingredients: [String]
    let confidence: Double
    let reasoning: String
    let modifications: String?
    let servingSize: String
    
    var macroBreakdown: String {
        "P: \(Int(protein))g | C: \(Int(carbs))g | F: \(Int(fat))g"
    }
    
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
}

// MARK: - Errors

enum FoodRecognitionError: LocalizedError {
    case invalidImage
    case invalidURL
    case apiError
    case httpError(statusCode: Int)
    case parsingError
    case noFoodDetected
    case safetyBlocked
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process image."
        case .invalidURL:
            return "Invalid API configuration."
        case .apiError:
            return "Network connection failed."
        case .httpError(let statusCode):
            return "Server error (Code: \(statusCode)). Check API key/Quota."
        case .parsingError:
            return "Could not read AI response. Please try again."
        case .noFoodDetected:
            return "No food detected in image."
        case .safetyBlocked:
            return "AI flagged this image as unsafe or unclear."
        }
    }
}
