//
//  MediVisionViewModel.swift
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
    
    // This holds the current result being reviewed (from a new scan)
    @Published var currentScanResult: MedicationAnalysisResult?
    
    // This holds the MASTER schedule (persistent)
    @Published var masterSchedule: MedicationAnalysisResult = MedicationAnalysisResult()
    
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
    private let masterScheduleKey = "masterMedicationSchedule" // Key for saving the main schedule
    
    // MARK: - Computed Properties
    
    var displayResult: MedicationAnalysisResult {
        // If we have a translation, use it for display
        if let translated = translatedContent {
            return MedicationAnalysisResult(
                medications: translated.medications,
                schedule: masterSchedule.schedule, // Use master schedule structure
                warnings: translated.warnings
            )
        }
        return masterSchedule
    }
    
    var translatedLabels: UILabels? {
        translatedContent?.labels
    }
    
    // MARK: - Initialization
    
    init() {
        loadHistory()
        loadMasterSchedule()
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
                    self.currentScanResult = result
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
    
    // MARK: - Schedule Management (Master Schedule)
    
    func approveCurrentScan() {
        guard let scan = currentScanResult else { return }
        
        // Merge scanned medications into master schedule
        masterSchedule.medications.append(contentsOf: scan.medications)
        masterSchedule.warnings.append(contentsOf: scan.warnings)
        
        // Merge schedule slots
        for id in scan.schedule.morning { masterSchedule.schedule.morning.append(id) }
        for id in scan.schedule.noon { masterSchedule.schedule.noon.append(id) }
        for id in scan.schedule.evening { masterSchedule.schedule.evening.append(id) }
        for id in scan.schedule.bedtime { masterSchedule.schedule.bedtime.append(id) }
        
        saveMasterSchedule()
        
        // Reset scan state but keep the view on the approved schedule
        currentScanResult = nil
        selectedImages.removeAll()
        
        // FIX: Reset to .idle so the system is ready for the NEXT scan immediately
        status = .idle
    }
    
    func deleteMedication(id: String) {
        // Remove from medication list
        masterSchedule.medications.removeAll { $0.id == id }
        
        // Remove from all time slots
        masterSchedule.schedule.morning.removeAll { $0 == id }
        masterSchedule.schedule.noon.removeAll { $0 == id }
        masterSchedule.schedule.evening.removeAll { $0 == id }
        masterSchedule.schedule.bedtime.removeAll { $0 == id }
        
        saveMasterSchedule()
    }
    
    func updateMedication(_ updatedMed: Medication) {
        if let index = masterSchedule.medications.firstIndex(where: { $0.id == updatedMed.id }) {
            masterSchedule.medications[index] = updatedMed
            saveMasterSchedule()
        }
    }
    
    func moveMedication(id: String, from: TimeSlot, to: TimeSlot) {
        // Remove from old slot
        masterSchedule.schedule[from].removeAll { $0 == id }
        
        // Add to new slot if not already there
        if !masterSchedule.schedule[to].contains(id) {
            masterSchedule.schedule[to].append(id)
        }
        
        saveMasterSchedule()
    }
    
    func addNewManualMedication(name: String, dosage: String, frequency: String, timeSlot: TimeSlot) {
        let newMed = Medication(
            name: name,
            dosage: dosage,
            frequency: frequency,
            instructions: "Manually added",
            source: .home,
            category: .prescription
        )
        
        masterSchedule.medications.append(newMed)
        masterSchedule.schedule[timeSlot].append(newMed.id)
        saveMasterSchedule()
    }
    
    func resetFlow() {
        selectedImages.removeAll()
        currentScanResult = nil
        // We do NOT reset masterSchedule here, as we want to keep the schedule
        status = .idle
    }
    
    // MARK: - Translation
    
    private func translateSchedule() {
        // Translate the MASTER schedule
        guard !masterSchedule.medications.isEmpty, selectedLanguage != "English" else { return }
        
        isTranslating = true
        
        Task {
            do {
                let translated = try await service.translateSchedule(masterSchedule, to: selectedLanguage)
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
        let result = displayResult
        
        let pdfGenerator = MediVisionPDFGenerator()
        let fileName = "MedicationSchedule-\(selectedLanguage).pdf"
        
        if let url = pdfGenerator.generatePDF(
            schedule: result.schedule,
            medications: result.medications,
            warnings: result.warnings,
            scheduleName: scheduleName.isEmpty ? "My Schedule" : scheduleName,
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
    
    // MARK: - Persistence
    
    private func saveMasterSchedule() {
        if let encoded = try? JSONEncoder().encode(masterSchedule) {
            UserDefaults.standard.set(encoded, forKey: masterScheduleKey)
        }
    }
    
    private func loadMasterSchedule() {
        if let data = UserDefaults.standard.data(forKey: masterScheduleKey),
           let decoded = try? JSONDecoder().decode(MedicationAnalysisResult.self, from: data) {
            masterSchedule = decoded
            // FIX: Set to idle so the add button works even if we have existing data
            status = .idle
        }
    }
    
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
}
