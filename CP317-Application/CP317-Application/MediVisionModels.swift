//
//  MediVisionModels.swift
//  CP317-Application
//
//  Models for the ORIGINAL MediVision pill bottle scanner feature
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Original MediVision Data Structures

struct MediVisionTimeSlot {
    let name: String
    let time: String
    let medications: [MediVisionMedication]
    
    init(name: String, time: String, medications: [MediVisionMedication]) {
        self.name = name
        self.time = time
        self.medications = medications
    }
}

struct MedicationSchedule {
    let timeSlots: [MediVisionTimeSlot]
    let warnings: [String]?
    
    init(timeSlots: [MediVisionTimeSlot], warnings: [String]? = nil) {
        self.timeSlots = timeSlots
        self.warnings = warnings
    }
}

struct MediVisionMedication {
    let name: String
    let dosage: String
    let instructions: String?
    
    init(name: String, dosage: String, instructions: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.instructions = instructions
    }
}

// MARK: - Scanned Image Item

struct ScannedImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let type: ScanType
    
    enum ScanType: String {
        case discharge = "Discharge Papers"
        case bottle = "Pill Bottle"
    }
}
