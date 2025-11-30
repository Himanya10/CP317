//
//  MedicationReconciliationViewModel.swift
//  CP317-Application
//

import Foundation
import SwiftUI
import PDFKit

enum ReconciliationStatus {
    case idle
    case analyzing
    case reviewPending
    case approved
}

@MainActor
class MedicationReconciliationViewModel: ObservableObject {
    
    enum ScanType {
            case bottleLabel
            case instructionSheet
        }
    // MARK: - Published Properties
    
    @Published var status: ReconciliationStatus = .idle
    @Published var selectedImages: [UIImage] = []
    @Published var analysisResult: MedicationAnalysisResult?
    @Published var scheduleName: String = ""
    @Published var errorMessage: String?
    @Published var history: [MedicationHistoryRecord] = []
    
    // Translation
    @Published var selectedLanguage: String = "English" {
        didSet {
            if selectedLanguage != "English" {
                translateSchedule()
            } else {
                translatedContent = nil
            }
        }
    }
    @Published var translatedContent: TranslatedContent?
    @Published var isTranslating: Bool = false
    
    // MARK: - Private Properties
    
    private let service = MedicationGeminiService.shared
    private let historyKey = "medicationReconciliationHistory"
    
    // MARK: - Computed Properties
    
    var displayResult: MedicationAnalysisResult? {
        if let translated = translatedContent {
            return MedicationAnalysisResult(
                medications: translated.medications,
                schedule: analysisResult?.schedule ?? DailySchedule(),
                warnings: translated.warnings
            )
        }
        return analysisResult
    }
    
    var translatedLabels: UILabels? {
        translatedContent?.labels
    }
    
    // MARK: - Initialization
    
    init() {
        loadHistory()
    }
    
    // MARK: - Image Management
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    // MARK: - Analysis
    
    func analyzeImages() {
        guard !selectedImages.isEmpty else {
            errorMessage = "Please add images to analyze"
            return
        }
        
        status = .analyzing
        errorMessage = nil
        translatedContent = nil
        selectedLanguage = "English"
        
        Task {
            do {
                let result = try await service.analyzeMedicationImages(selectedImages)
                await MainActor.run {
                    self.analysisResult = result
                    self.status = .reviewPending
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.status = .idle
                }
            }
        }
    }
    
    // MARK: - Schedule Management
    
    func moveMedication(id: String, from: TimeSlot, to: TimeSlot) {
        guard var result = analysisResult else { return }
        
        // Remove from old slot
        result.schedule[from].removeAll { $0 == id }
        
        // Add to new slot if not already there
        if !result.schedule[to].contains(id) {
            result.schedule[to].append(id)
        }
        
        analysisResult = result
    }
    
    func updateMedication(id: String, field: WritableKeyPath<Medication, String>, value: String) {
        guard var result = analysisResult else { return }
        
        if let index = result.medications.firstIndex(where: { $0.id == id }) {
            result.medications[index][keyPath: field] = value
            analysisResult = result
        }
    }
    
    func approveSchedule() {
        guard let result = analysisResult else { return }
        
        let finalName = scheduleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Schedule \(history.count + 1)"
            : scheduleName
        
        scheduleName = finalName
        
        let record = MedicationHistoryRecord(
            date: Date(),
            scheduleName: finalName,
            data: result
        )
        
        history.insert(record, at: 0)
        saveHistory()
        
        status = .approved
    }
    
    func resetFlow() {
        selectedImages.removeAll()
        analysisResult = nil
        scheduleName = ""
        translatedContent = nil
        selectedLanguage = "English"
        errorMessage = nil
        status = .idle
    }
    
    func loadFromHistory(_ record: MedicationHistoryRecord) {
        analysisResult = record.data
        scheduleName = record.scheduleName
        translatedContent = nil
        selectedLanguage = "English"
        status = .approved
    }
    
    // MARK: - Translation
    
    private func translateSchedule() {
        guard let result = analysisResult, selectedLanguage != "English" else {
            return
        }
        
        isTranslating = true
        
        Task {
            do {
                let translated = try await service.translateSchedule(result, to: selectedLanguage)
                await MainActor.run {
                    self.translatedContent = translated
                    self.isTranslating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Translation failed: \(error.localizedDescription)"
                    self.isTranslating = false
                    self.selectedLanguage = "English"
                }
            }
        }
    }
    
    // MARK: - PDF Export
    
    func exportToPDF() {
        guard let result = displayResult else { return }
        
        let pdfGenerator = MediVisionPDFGenerator()
        let fileName = "\(scheduleName)-\(selectedLanguage).pdf"
        
        if let url = pdfGenerator.generatePDF(
            schedule: result.schedule,
            medications: result.medications,
            warnings: result.warnings,
            scheduleName: scheduleName,
            labels: translatedLabels,
            fileName: fileName
        ) {
            // Share the PDF
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } else {
            errorMessage = "Failed to generate PDF"
        }
    }
    
    // MARK: - History Management
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([MedicationHistoryRecord].self, from: data) {
            history = decoded
        }
    }
    
    func deleteHistoryRecord(_ record: MedicationHistoryRecord) {
        history.removeAll { $0.id == record.id }
        saveHistory()
    }
}
