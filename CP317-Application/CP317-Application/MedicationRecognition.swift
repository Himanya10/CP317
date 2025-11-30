//
//  MedicationGeminiService.swift
//  CP317-Application
//

import Foundation
import UIKit

class MedicationGeminiService {
    static let shared = MedicationGeminiService()
    
    private let apiKey = Config.geminiAPIKey
    // UPDATED: Changed from 'gemini-1.5-flash' to 'gemini-2.5-flash' to fix 404 error
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private init() {}
    
    // MARK: - Request/Response Models
    
    struct GeminiRequest: Codable {
        let contents: [Content]
        let generationConfig: GenerationConfig?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String?
                let inlineData: InlineData?
                
                struct InlineData: Codable {
                    let mimeType: String
                    let data: String
                }
            }
        }
        
        struct GenerationConfig: Codable {
            let temperature: Double?
            let topK: Int?
            let topP: Double?
            let maxOutputTokens: Int?
        }
    }
    
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let error: APIError?
        
        struct Candidate: Codable {
            let content: Content
            
            struct Content: Codable {
                let parts: [Part]
                
                struct Part: Codable {
                    let text: String
                }
            }
        }
        
        struct APIError: Codable {
            let message: String
            let code: Int
        }
    }
    
    // MARK: - Main Analysis Function
    
    func analyzeMedicationImages(_ images: [UIImage]) async throws -> MedicationAnalysisResult {
        var parts: [GeminiRequest.Content.Part] = []
        
        // Add the prompt
        let prompt = buildAnalysisPrompt()
        parts.append(GeminiRequest.Content.Part(text: prompt, inlineData: nil))
        
        // Add images
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let base64String = imageData.base64EncodedString()
            
            let inlineData = GeminiRequest.Content.Part.InlineData(
                mimeType: "image/jpeg",
                data: base64String
            )
            parts.append(GeminiRequest.Content.Part(text: nil, inlineData: inlineData))
        }
        
        let request = GeminiRequest(
            contents: [GeminiRequest.Content(parts: parts)],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.4,
                topK: 32,
                topP: 1,
                maxOutputTokens: 4096
            )
        )
        
        // Make API call
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw MedicationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MedicationError.invalidResponse
        }
        
        // Detailed error logging for debugging
        guard httpResponse.statusCode == 200 else {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("DEBUG: MediVision Gemini Error \(httpResponse.statusCode): \(errorBody)")
            }
            throw MedicationError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        if let error = geminiResponse.error {
            throw MedicationError.apiError(message: error.message)
        }
        
        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw MedicationError.noResponse
        }
        
        // Parse the JSON response
        return try parseAnalysisResult(text)
    }
    
    // MARK: - Translation Function
    
    func translateSchedule(_ result: MedicationAnalysisResult, to language: String) async throws -> TranslatedContent {
        let prompt = buildTranslationPrompt(result: result, language: language)
        
        let request = GeminiRequest(
            contents: [GeminiRequest.Content(parts: [
                GeminiRequest.Content.Part(text: prompt, inlineData: nil)
            ])],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.3,
                topK: 32,
                topP: 1,
                maxOutputTokens: 4096
            )
        )
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw MedicationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MedicationError.invalidResponse
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw MedicationError.noResponse
        }
        
        return try parseTranslationResult(text)
    }
    
    // MARK: - Prompt Building
    
    private func buildAnalysisPrompt() -> String {
        return """
        You are a clinical pharmacist AI assistant helping patients reconcile their medications during care transitions.
        
        Analyze the provided images which may include:
        - Hospital discharge summaries with prescribed medications
        - Pill bottle labels with dosage instructions
        
        For each medication found, extract:
        1. Medication name (generic and/or brand name)
        2. Dosage amount (e.g., "10mg", "500mg")
        3. Frequency (e.g., "once daily", "twice daily", "as needed")
        4. Complete instructions (timing, with food, etc.)
        5. Source (HOSPITAL for discharge papers, HOME for pill bottles)
        6. Category (OTC for over-the-counter, Rx for prescription)
        
        CRITICAL INSTRUCTIONS:
        - For pill bottles: ONLY read PRIMARY label text, IGNORE ingredient lists and warnings
        - Focus on dosage instructions like "Take 1 tablet daily"
        - If timing is not specified, use clinical judgment to assign appropriate time slot
        - Check for drug interactions and duplicate therapies
        
        Organize medications into time slots:
        - morning: 6:00 AM - 11:00 AM
        - noon: 11:00 AM - 2:00 PM
        - evening: 2:00 PM - 8:00 PM
        - bedtime: 8:00 PM - 6:00 AM
        
        Identify clinical warnings:
        - Drug-drug interactions
        - Duplicate therapies
        - Dosing concerns
        - Missing critical medications
        
        Return ONLY valid JSON in this EXACT format (no markdown, no extra text):
        {
          "medications": [
            {
              "id": "unique-id",
              "name": "Medication Name",
              "dosage": "10mg",
              "frequency": "once daily",
              "instructions": "Take with food in the morning",
              "source": "HOSPITAL",
              "category": "Rx",
              "reasoning": "Assigned to morning based on standard administration time"
            }
          ],
          "schedule": {
            "morning": ["med-id-1", "med-id-2"],
            "noon": [],
            "evening": ["med-id-3"],
            "bedtime": ["med-id-4"]
          },
          "warnings": [
            {
              "id": "warning-id",
              "description": "Warning description",
              "relatedMedicationIds": ["med-id-1", "med-id-2"]
            }
          ]
        }
        """
    }
    
    private func buildTranslationPrompt(result: MedicationAnalysisResult, language: String) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let jsonData = try? encoder.encode(result),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return ""
        }
        
        return """
        Translate the following medication schedule to \(language).
        
        IMPORTANT:
        - Translate medication names if there are standard translations in \(language)
        - Translate all instructions and warnings
        - Translate all UI labels
        - Keep the same JSON structure
        - Keep medication IDs unchanged
        - Maintain medical accuracy
        
        Original schedule:
        \(jsonString)
        
        Return ONLY valid JSON with this structure (no markdown):
        {
          "medications": [/* translated medication objects */],
          "warnings": [/* translated warnings */],
          "labels": {
            "reportTitle": "Medication Schedule",
            "reportSubtitle": "Daily Administration Plan",
            "scheduleNameLabel": "Schedule Name",
            "dateLabel": "Date",
            "clinicalAlertsTitle": "Clinical Alerts",
            "morning": "Morning",
            "morningTime": "8:00 AM",
            "noon": "Noon",
            "noonTime": "12:00 PM",
            "evening": "Evening",
            "eveningTime": "6:00 PM",
            "night": "Bedtime",
            "nightTime": "10:00 PM",
            "tableMedication": "Medication",
            "tableType": "Type",
            "tableInstructions": "Instructions",
            "tableAdministered": "Administered",
            "disclaimer": "This schedule was generated by AI. Always consult your healthcare provider before making changes to your medications.",
            "signature": "Patient/Caregiver Signature",
            "labelOTC": "OTC",
            "labelRx": "Rx"
          }
        }
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseAnalysisResult(_ text: String) throws -> MedicationAnalysisResult {
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean markdown
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
            throw MedicationError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MedicationAnalysisResult.self, from: jsonData)
    }
    
    private func parseTranslationResult(_ text: String) throws -> TranslatedContent {
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean markdown
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
            throw MedicationError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(TranslatedContent.self, from: jsonData)
    }
}

// MARK: - Error Types

enum MedicationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(message: String)
    case noResponse
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noResponse:
            return "No response from AI"
        case .parsingError:
            return "Failed to parse medication data"
        }
    }
}
