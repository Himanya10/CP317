//
//  MedicationModels.swift
//  CP317-Application
//

import Foundation
import SwiftUI

// MARK: - Enums

enum SourceType: String, Codable {
    case hospital = "HOSPITAL"
    case home = "HOME"
}

enum MedicationCategory: String, Codable {
    case otc = "OTC"
    case prescription = "Rx"
}

enum TimeSlot: String, Codable, CaseIterable {
    case morning = "morning"
    case noon = "noon"
    case evening = "evening"
    case bedtime = "bedtime"
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .noon: return "Noon"
        case .evening: return "Evening"
        case .bedtime: return "Bedtime"
        }
    }
    
    var time: String {
        switch self {
        case .morning: return "8:00 AM"
        case .noon: return "12:00 PM"
        case .evening: return "6:00 PM"
        case .bedtime: return "10:00 PM"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .bedtime: return "moon.stars.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morning: return .orange
        case .noon: return .yellow
        case .evening: return .purple
        case .bedtime: return .blue
        }
    }
}

// MARK: - Medication Model

struct Medication: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var dosage: String
    var frequency: String
    var instructions: String
    var source: SourceType
    var category: MedicationCategory
    var reasoning: String?
    
    init(id: String = UUID().uuidString,
         name: String,
         dosage: String,
         frequency: String,
         instructions: String,
         source: SourceType,
         category: MedicationCategory,
         reasoning: String? = nil) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.instructions = instructions
        self.source = source
        self.category = category
        self.reasoning = reasoning
    }
}

// MARK: - Schedule Model

struct DailySchedule: Codable, Equatable {
    var morning: [String]
    var noon: [String]
    var evening: [String]
    var bedtime: [String]
    
    init(morning: [String] = [], noon: [String] = [], evening: [String] = [], bedtime: [String] = []) {
        self.morning = morning
        self.noon = noon
        self.evening = evening
        self.bedtime = bedtime
    }
    
    subscript(slot: TimeSlot) -> [String] {
        get {
            switch slot {
            case .morning: return morning
            case .noon: return noon
            case .evening: return evening
            case .bedtime: return bedtime
            }
        }
        set {
            switch slot {
            case .morning: morning = newValue
            case .noon: noon = newValue
            case .evening: evening = newValue
            case .bedtime: bedtime = newValue
            }
        }
    }
}

// MARK: - Warning Model

struct MedicationWarning: Identifiable, Codable, Equatable {
    let id: String
    let description: String
    let relatedMedicationIds: [String]
    
    init(id: String = UUID().uuidString, description: String, relatedMedicationIds: [String]) {
        self.id = id
        self.description = description
        self.relatedMedicationIds = relatedMedicationIds
    }
}

// MARK: - Analysis Result

struct MedicationAnalysisResult: Codable, Equatable {
    var medications: [Medication]
    var schedule: DailySchedule
    var warnings: [MedicationWarning]
    
    init(medications: [Medication] = [], schedule: DailySchedule = DailySchedule(), warnings: [MedicationWarning] = []) {
        self.medications = medications
        self.schedule = schedule
        self.warnings = warnings
    }
}

// MARK: - History Record

struct MedicationHistoryRecord: Identifiable, Codable {
    let id: String
    let date: Date
    let scheduleName: String
    let data: MedicationAnalysisResult
    
    init(id: String = UUID().uuidString, date: Date = Date(), scheduleName: String, data: MedicationAnalysisResult) {
        self.id = id
        self.date = date
        self.scheduleName = scheduleName
        self.data = data
    }
}

// MARK: - Translation Models

struct UILabels: Codable {
    let reportTitle: String
    let reportSubtitle: String
    let scheduleNameLabel: String
    let dateLabel: String
    let clinicalAlertsTitle: String
    let morning: String
    let morningTime: String
    let noon: String
    let noonTime: String
    let evening: String
    let eveningTime: String
    let night: String
    let nightTime: String
    let tableMedication: String
    let tableType: String
    let tableInstructions: String
    let tableAdministered: String
    let disclaimer: String
    let signature: String
    let labelOTC: String
    let labelRx: String
}

struct TranslatedContent: Codable {
    let medications: [Medication]
    let warnings: [MedicationWarning]
    let labels: UILabels
}
