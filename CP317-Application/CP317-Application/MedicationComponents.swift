//
//  MedicationReconciliationComponents.swift
//  CP317-Application
//

import SwiftUI
import PhotosUI

// MARK: - Image Picker

struct ReconciliationImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 10
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ReconciliationImagePicker
        
        init(_ parent: ReconciliationImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Picker

struct ReconciliationCameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReconciliationCameraPicker
        
        init(_ parent: ReconciliationCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Medication List View

struct ReconciliationMedicationList: View {
    let medications: [Medication]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medications (\(medications.count))")
                .font(.headline)
                .foregroundColor(.lightText)
            
            ForEach(medications) { med in
                ReconciliationMedicationCard(medication: med)
            }
        }
    }
}

struct ReconciliationMedicationCard: View {
    let medication: Medication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Category Badge
                Text(medication.category.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(medication.category == .prescription ? .blue : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(medication.category == .prescription ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    )
                
                // Source Badge
                Image(systemName: medication.source == .hospital ? "building.2.crop.circle" : "house.circle")
                    .foregroundColor(medication.source == .hospital ? .orange : .purple)
            }
            
            if !medication.instructions.isEmpty {
                Text(medication.instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !medication.frequency.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.pgAccent)
                        .font(.caption)
                    Text(medication.frequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground.opacity(0.6))
        )
    }
}

// MARK: - Schedule View

struct ReconciliationScheduleView: View {
    let schedule: DailySchedule
    let medications: [Medication]
    var warnings: [MedicationWarning]?
    var isEditable: Bool = false
    var scheduleName: String?
    var labels: UILabels?
    var onMove: ((String, TimeSlot, TimeSlot) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let name = scheduleName {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labels?.reportTitle ?? "Medication Schedule")
                        .font(.title.bold())
                        .foregroundColor(.lightText)
                    
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            
            // Warnings
            if let warnings = warnings, !warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(labels?.clinicalAlertsTitle ?? "Clinical Alerts")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    ForEach(warnings) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(warning.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.bottom)
            }
            
            // Time Slots
            ForEach(TimeSlot.allCases, id: \.self) { slot in
                ReconciliationTimeSlotView(
                    slot: slot,
                    medicationIds: schedule[slot],
                    medications: medications,
                    isEditable: isEditable,
                    labels: labels,
                    onMove: onMove
                )
            }
            
            // Disclaimer
            if let disclaimer = labels?.disclaimer {
                Text(disclaimer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cardBackground.opacity(0.3))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
    }
}

struct ReconciliationTimeSlotView: View {
    let slot: TimeSlot
    let medicationIds: [String]
    let medications: [Medication]
    var isEditable: Bool
    var labels: UILabels?
    var onMove: ((String, TimeSlot, TimeSlot) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: slot.icon)
                    .foregroundColor(slot.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedSlotName)
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    Text(slot.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(medicationIds.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(slot.color))
            }
            
            if medicationIds.isEmpty {
                Text("No medications")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(medicationIds, id: \.self) { medId in
                    if let med = medications.first(where: { $0.id == medId }) {
                        ReconciliationMedicationRow(medication: med, labels: labels)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(slot.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(slot.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var localizedSlotName: String {
        guard let labels = labels else { return slot.displayName }
        
        switch slot {
        case .morning: return labels.morning
        case .noon: return labels.noon
        case .evening: return labels.evening
        case .bedtime: return labels.night
        }
    }
}

struct ReconciliationMedicationRow: View {
    let medication: Medication
    var labels: UILabels?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pill.fill")
                .foregroundColor(.pgAccent)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.lightText)
                
                Text(medication.dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !medication.instructions.isEmpty {
                    Text(medication.instructions)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(categoryLabel)
                .font(.caption2.bold())
                .foregroundColor(medication.category == .prescription ? .blue : .green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(medication.category == .prescription ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                )
        }
        .padding(.vertical, 4)
    }
    
    private var categoryLabel: String {
        guard let labels = labels else {
            return medication.category.rawValue
        }
        
        return medication.category == .prescription ? labels.labelRx : labels.labelOTC
    }
}

// MARK: - History View

struct MedicationReconciliationHistoryView: View {
    @ObservedObject var viewModel: MedicationReconciliationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.history) { record in
                    Button(action: {
                        viewModel.loadFromHistory(record)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.scheduleName)
                                .font(.headline)
                                .foregroundColor(.lightText)
                            
                            HStack {
                                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(record.data.medications.count) meds")
                                    .font(.caption)
                                    .foregroundColor(.pgAccent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteHistoryRecord(record)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
