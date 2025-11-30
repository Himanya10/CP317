//
//  FoodRecognitionService.swift
//  CP317-Application
//

import Foundation
import UIKit

class FoodRecognitionService {
    static let shared = FoodRecognitionService()
    
    private let apiKey = Config.geminiAPIKey
    private let visionEndpoint = "https://vision.googleapis.com/v1/images:annotate"
    private let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    private init() {}
    
    // MARK: - Main Food Analysis Function
    
    func analyzeFood(image: UIImage, userModifications: String? = nil) async throws -> FoodAnalysisResult {
        // Step 1: Use Vision API to detect text and labels
        let visionResult = try await detectFoodWithVision(image: image)
        
        // Step 2: Use Gemini to analyze and estimate calories
        let analysis = try await analyzeFoodWithGemini(
            image: image,
            detectedText: visionResult.text,
            detectedLabels: visionResult.labels,
            userModifications: userModifications
        )
        
        return analysis
    }
    
    // MARK: - Vision API for OCR and Label Detection
    
    private func detectFoodWithVision(image: UIImage) async throws -> VisionResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "TEXT_DETECTION", "maxResults": 10],
                        ["type": "LABEL_DETECTION", "maxResults": 10],
                        ["type": "OBJECT_LOCALIZATION", "maxResults": 10]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: "\(visionEndpoint)?key=\(apiKey)") else {
            throw FoodRecognitionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodRecognitionError.apiError
        }
        
        return try parseVisionResponse(data)
    }
    
    private func parseVisionResponse(_ data: Data) throws -> VisionResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let responses = json?["responses"] as? [[String: Any]],
              let firstResponse = responses.first else {
            throw FoodRecognitionError.parsingError
        }
        
        // Extract text
        var detectedText = ""
        if let textAnnotations = firstResponse["textAnnotations"] as? [[String: Any]],
           let fullText = textAnnotations.first?["description"] as? String {
            detectedText = fullText
        }
        
        // Extract labels
        var labels: [String] = []
        if let labelAnnotations = firstResponse["labelAnnotations"] as? [[String: Any]] {
            labels = labelAnnotations.compactMap { $0["description"] as? String }
        }
        
        return VisionResult(text: detectedText, labels: labels)
    }
    
    // MARK: - Gemini AI for Calorie Analysis
    
    private func analyzeFoodWithGemini(
        image: UIImage,
        detectedText: String,
        detectedLabels: [String],
        userModifications: String?
    ) async throws -> FoodAnalysisResult {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = buildGeminiPrompt(
            detectedText: detectedText,
            detectedLabels: detectedLabels,
            userModifications: userModifications
        )
        
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
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodRecognitionError.apiError
        }
        
        return try parseGeminiResponse(data)
    }
    
    private func buildGeminiPrompt(detectedText: String, detectedLabels: [String], userModifications: String?) -> String {
        var prompt = """
        You are a nutrition expert AI. Analyze this food image and provide detailed nutritional information.
        
        """
        
        if !detectedText.isEmpty {
            prompt += """
            Detected text from image (menu items, nutrition labels, etc.):
            \(detectedText)
            
            """
        }
        
        if !detectedLabels.isEmpty {
            prompt += """
            Detected food labels: \(detectedLabels.joined(separator: ", "))
            
            """
        }
        
        if let modifications = userModifications, !modifications.isEmpty {
            prompt += """
            User's additional information or modifications:
            \(modifications)
            
            """
        }
        
        prompt += """
        
        Please analyze the food and provide:
        1. Identify all food items visible in the image
        2. Estimate portion sizes
        3. Calculate total calories
        4. Provide macronutrient breakdown (protein, carbs, fat)
        5. List key ingredients if visible
        6. Note any modifications or additions mentioned by the user
        
        IMPORTANT: Return ONLY valid JSON in this exact format (no markdown, no extra text):
        {
          "foodName": "Name of the main dish or food item",
          "description": "Brief description of what you see",
          "portionSize": "Estimated portion (e.g., '1 medium burger', '2 cups', '350g')",
          "calories": 450,
          "protein": 25,
          "carbs": 35,
          "fat": 20,
          "fiber": 5,
          "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
          "confidence": 0.85,
          "reasoning": "Brief explanation of how you estimated the calories",
          "modifications": "Summary of user modifications if any",
          "servingSize": "Standard serving size (e.g., '1 burger', '1 plate')"
        }
        
        Be as accurate as possible with calorie estimates. If you're uncertain, err on the side of caution and provide a range in the reasoning field.
        """
        
        return prompt
    }
    
    private func parseGeminiResponse(_ data: Data) throws -> FoodAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw FoodRecognitionError.parsingError
        }
        
        // Clean the response
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        }
        if cleanText.hasPrefix("```") {
            cleanText = cleanText.replacingOccurrences(of: "```", with: "")
        }
        if cleanText.hasSuffix("```") {
            cleanText = String(cleanText.dropLast(3))
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanText.data(using: .utf8) else {
            throw FoodRecognitionError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FoodAnalysisResult.self, from: jsonData)
    }
}

// MARK: - Models

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
    case parsingError
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process image"
        case .invalidURL:
            return "Invalid API endpoint"
        case .apiError:
            return "API request failed"
        case .parsingError:
            return "Unable to parse response"
        case .noFoodDetected:
            return "No food detected in image"
        }
    }
}
