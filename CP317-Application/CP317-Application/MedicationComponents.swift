//
//  MedicationReconciliationComponents.swift
//  CP317-Application
//

import SwiftUI
import PhotosUI

// MARK: - Image Picker (No changes needed)
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
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ReconciliationImagePicker
        init(_ parent: ReconciliationImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async { self.parent.images.append(image) }
                        }
                    }
                }
            }
        }
    }
}

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
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReconciliationCameraPicker
        init(_ parent: ReconciliationCameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - Medication List Components
struct ReconciliationMedicationList: View {
    let medications: [Medication]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medications Found (\(medications.count))")
                .font(.headline)
                .foregroundColor(.lightText)
            ForEach(medications) { med in ReconciliationMedicationCard(medication: med) }
        }
    }
}

struct ReconciliationMedicationCard: View {
    let medication: Medication
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name).font(.headline).foregroundColor(.lightText)
                    Text(medication.dosage).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text(medication.category.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(medication.category == .prescription ? .blue : .green)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(medication.category == .prescription ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)))
            }
            if !medication.frequency.isEmpty {
                HStack {
                    Image(systemName: "clock").foregroundColor(.pgAccent).font(.caption)
                    Text(medication.frequency).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground.opacity(0.6)))
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
    var onDelete: ((String) -> Void)?
    var onEdit: ((Medication) -> Void)?
    var onAdd: ((TimeSlot) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let name = scheduleName {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labels?.reportTitle ?? "My Schedule").font(.title.bold()).foregroundColor(.lightText)
                    if !name.isEmpty { Text(name).font(.subheadline).foregroundColor(.secondary) }
                }
                .padding(.bottom)
            }
            if let warnings = warnings, !warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text(labels?.clinicalAlertsTitle ?? "Clinical Alerts").font(.headline).foregroundColor(.red)
                    }
                    ForEach(warnings) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.red).frame(width: 6, height: 6).padding(.top, 6)
                            Text(warning.description).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding().background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1))).padding(.bottom)
            }
            ForEach(TimeSlot.allCases, id: \.self) { slot in
                ReconciliationTimeSlotView(
                    slot: slot, medicationIds: schedule[slot], medications: medications, isEditable: isEditable, labels: labels,
                    onMove: onMove, onDelete: onDelete, onEdit: onEdit, onAdd: onAdd
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.cardBackground))
    }
}

struct ReconciliationTimeSlotView: View {
    let slot: TimeSlot
    let medicationIds: [String]
    let medications: [Medication]
    var isEditable: Bool
    var labels: UILabels?
    var onMove: ((String, TimeSlot, TimeSlot) -> Void)?
    var onDelete: ((String) -> Void)?
    var onEdit: ((Medication) -> Void)?
    var onAdd: ((TimeSlot) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: slot.icon).foregroundColor(slot.color).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedSlotName).font(.headline).foregroundColor(.lightText)
                    Text(slot.time).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if isEditable {
                    Button(action: { onAdd?(slot) }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.pgAccent).font(.title3)
                    }
                }
            }
            if medicationIds.isEmpty {
                Text("No medications").font(.caption).foregroundColor(.secondary).italic()
            } else {
                ForEach(medicationIds, id: \.self) { medId in
                    if let med = medications.first(where: { $0.id == medId }) {
                        ReconciliationMedicationRow(
                            medication: med, labels: labels, isEditable: isEditable,
                            onDelete: { onDelete?(medId) }, onEdit: { onEdit?(med) }
                        )
                    }
                }
            }
        }
        .padding().background(RoundedRectangle(cornerRadius: 16).fill(slot.color.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(slot.color.opacity(0.3), lineWidth: 1))
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
    var isEditable: Bool
    var onDelete: (() -> Void)?
    var onEdit: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pill.fill").foregroundColor(.pgAccent).font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name).font(.subheadline.bold()).foregroundColor(.lightText)
                HStack {
                    Text(medication.dosage)
                    if !medication.frequency.isEmpty { Text("• \(medication.frequency)") }
                }
                .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if isEditable {
                Menu {
                    Button(action: { onEdit?() }) { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive, action: { onDelete?() }) { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.secondary).padding(8)
                }
            } else {
                Text(categoryLabel)
                    .font(.caption2.bold()).foregroundColor(medication.category == .prescription ? .blue : .green)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(medication.category == .prescription ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)))
            }
        }
        .padding(.vertical, 4)
    }
    private var categoryLabel: String {
        guard let labels = labels else { return medication.category.rawValue }
        return medication.category == .prescription ? labels.labelRx : labels.labelOTC
    }
}

// MARK: - Edit Medication Sheet

struct EditMedicationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var dosage: String
    @State private var frequency: String
    @State private var category: MedicationCategory
    
    let medication: Medication
    let onSave: (Medication) -> Void
    
    // Explicitly included Weekly, Bi-weekly, Monthly options
    let frequencies = ["Daily", "2x Daily", "3x Daily", "Weekly", "Bi-weekly", "Monthly", "As Needed"]
    
    init(medication: Medication, onSave: @escaping (Medication) -> Void) {
        self.medication = medication
        self.onSave = onSave
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage)
        _frequency = State(initialValue: medication.frequency)
        _category = State(initialValue: medication.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g. 10mg)", text: $dosage)
                }
                
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                }
                
                Section("Type") {
                    Picker("Category", selection: $category) {
                        Text("Prescription (Rx)").tag(MedicationCategory.prescription)
                        Text("Over the Counter (OTC)").tag(MedicationCategory.otc)
                    }
                }
            }
            .navigationTitle("Edit Medication")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updated = medication
                        updated.name = name
                        updated.dosage = dosage
                        updated.frequency = frequency
                        updated.category = category
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Medication Sheet

struct AddMedicationSheet: View {
    @Environment(\.dismiss) var dismiss
    let timeSlot: TimeSlot
    let onAdd: (String, String, String, TimeSlot) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var selectedSlot: TimeSlot
    
    // Explicitly included Weekly, Bi-weekly, Monthly options
    let frequencies = ["Daily", "2x Daily", "3x Daily", "Weekly", "Bi-weekly", "Monthly", "As Needed"]
    
    init(timeSlot: TimeSlot, onAdd: @escaping (String, String, String, TimeSlot) -> Void) {
        self.timeSlot = timeSlot
        self.onAdd = onAdd
        _selectedSlot = State(initialValue: timeSlot)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("New Medication") {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage (e.g. 500mg)", text: $dosage)
                }
                
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                    
                    Picker("Time Slot", selection: $selectedSlot) {
                        ForEach(TimeSlot.allCases, id: \.self) { slot in
                            Text(slot.displayName).tag(slot)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(name, dosage, frequency, selectedSlot)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
