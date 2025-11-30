//
//  MediVisionView.swift
//  CP317-Application
//

import SwiftUI
import PhotosUI

struct MedicationReconciliationView: View {
    @StateObject private var viewModel = MedicationReconciliationViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    // State for editing sheets
    @State private var editingMedication: Medication?
    @State private var addingToSlot: TimeSlot?
    @State private var showingManualAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. If we are currently scanning/analyzing, show that flow
                        if viewModel.status == .analyzing {
                            analyzingSection
                        }
                        else if viewModel.status == .reviewPending {
                            // Show review of NEW items found
                            reviewNewScanSection
                        }
                        else {
                            // 2. Otherwise, show the Master Schedule (Main View)
                            masterScheduleSection
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("MediVision")
            .navigationBarTitleDisplayMode(.large)
            // Edit Sheet
            .sheet(item: $editingMedication) { med in
                EditMedicationSheet(medication: med) { updatedMed in
                    viewModel.updateMedication(updatedMed)
                }
            }
            // Add Sheet (Via Slot)
            .sheet(item: $addingToSlot) { slot in
                AddMedicationSheet(timeSlot: slot) { name, dose, freq, slot in
                    viewModel.addNewManualMedication(name: name, dosage: dose, frequency: freq, timeSlot: slot)
                }
            }
            // Manual Add Sheet (Global)
            .sheet(isPresented: $showingManualAddSheet) {
                AddMedicationSheet(timeSlot: .morning) { name, dose, freq, slot in
                    viewModel.addNewManualMedication(name: name, dosage: dose, frequency: freq, timeSlot: slot)
                }
            }
            // Image Pickers
            .sheet(isPresented: $showingImagePicker) {
                ReconciliationImagePicker(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showingCamera) {
                ReconciliationCameraPicker(image: Binding(
                    get: { nil },
                    set: { if let img = $0 { viewModel.addImage(img) } }
                ))
            }
            // Error Alert
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        // FIX: Allow analysis trigger even if status is .approved (after first upload)
        .onChange(of: viewModel.selectedImages) { images in
            if !images.isEmpty {
                // If we are in a browsing state (idle or approved), start analysis
                if viewModel.status == .idle || viewModel.status == .approved {
                    viewModel.analyzeImages()
                }
            }
        }
    }
    
    // MARK: - Master Schedule Section (Main View)
    
    private var masterScheduleSection: some View {
        VStack(spacing: 20) {
            
            // --- Top Header (View Only) ---
            HStack {
                Image(systemName: "cross.case.fill")
                    .font(.title)
                    .foregroundColor(.pgAccent)
                
                Text("My Schedule")
                    .font(.title2.bold())
                    .foregroundColor(.lightText)
                
                Spacer()
                
                // Language Picker
                Menu {
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        Text("Chinese").tag("Chinese (Simplified)")
                    }
                } label: {
                    Image(systemName: "globe")
                        .foregroundColor(.pgAccent)
                        .padding(8)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
                
                // PDF Button
                Button(action: { viewModel.exportToPDF() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.pgAccent)
                        .padding(8)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            // --- The Schedule List ---
            if viewModel.masterSchedule.medications.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("No medications yet")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        Text("Use the buttons below to create your schedule")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 40)
            } else {
                ReconciliationScheduleView(
                    schedule: viewModel.displayResult.schedule,
                    medications: viewModel.displayResult.medications,
                    warnings: viewModel.displayResult.warnings,
                    isEditable: true,
                    scheduleName: "",
                    labels: viewModel.translatedLabels,
                    onMove: { id, from, to in
                        viewModel.moveMedication(id: id, from: from, to: to)
                    },
                    onDelete: { id in
                        viewModel.deleteMedication(id: id)
                    },
                    onEdit: { med in
                        editingMedication = med
                    },
                    onAdd: { slot in
                        addingToSlot = slot
                    }
                )
                .padding(.horizontal)
            }
            
            // --- Bottom Action Section (Add More) ---
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Schedule")
                    .font(.headline)
                    .foregroundColor(.lightText)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    // 1. Scan Options
                    HStack(spacing: 12) {
                        Button(action: { showingCamera = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Scan Camera")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pgAccent)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Upload Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.pgAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pgAccent.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 2. Manual Add Option
                    Button(action: { showingManualAddSheet = true }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("Manually Add Medication")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Review New Scan Section
    
    private var reviewNewScanSection: some View {
        VStack(spacing: 20) {
            Text("Review Scanned Items")
                .font(.title2.bold())
                .foregroundColor(.lightText)
            
            Text("These items will be added to your existing schedule.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let result = viewModel.currentScanResult {
                ScrollView {
                    ReconciliationMedicationList(medications: result.medications)
                        .padding(.horizontal)
                }
                
                // Approve/Cancel Buttons
                HStack(spacing: 16) {
                    Button(action: { viewModel.resetFlow() }) {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { viewModel.approveCurrentScan() }) {
                        Text("Add to Schedule")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Analyzing Section
    private var analyzingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pgAccent)
            
            Text("Analyzing medications...")
                .font(.headline)
                .foregroundColor(.lightText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Extension to make TimeSlot Identifiable for sheet presentation
extension TimeSlot: Identifiable {
    public var id: String { self.rawValue }
}
