//
//  MedicationReconciliationView.swift
//  CP317-Application
//

import SwiftUI
import PhotosUI

struct MedicationReconciliationView: View {
    @StateObject private var viewModel = MedicationReconciliationViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.status == .idle {
                            heroSection
                            uploadSection
                        } else if viewModel.status == .analyzing {
                            analyzingSection
                        } else if viewModel.status == .reviewPending {
                            reviewSection
                        } else if viewModel.status == .approved {
                            approvedSection
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("MediVision")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.pgAccent)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ReconciliationImagePicker(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showingCamera) {
                ReconciliationCameraPicker(image: Binding(
                    get: { nil },
                    set: { if let img = $0 { viewModel.addImage(img) } }
                ))
            }
            .sheet(isPresented: $showingHistory) {
                MedicationReconciliationHistoryView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.pgAccent.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.pgAccent)
            }
            
            VStack(spacing: 8) {
                Text("Smart Medication Manager")
                    .font(.title.bold())
                    .foregroundColor(.lightText)
                
                Text("Scan discharge papers and pill bottles to create a unified medication schedule")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 32)
    }
    
    // MARK: - Upload Section
    
    private var uploadSection: some View {
        VStack(spacing: 16) {
            // Upload Card
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(.pgAccent.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.cardBackground.opacity(0.5))
                    )
                
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.pgAccent)
                    
                    Text("Upload Images")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    Text("Take photos or select from library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(action: { showingCamera = true }) {
                            Label("Camera", systemImage: "camera")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pgAccent)
                                .cornerRadius(12)
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .font(.subheadline.bold())
                                .foregroundColor(.pgAccent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pgAccent.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(32)
            }
            .frame(height: 320)
            .padding(.horizontal)
            
            // Preview Grid
            if !viewModel.selectedImages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scanned Items (\(viewModel.selectedImages.count))")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            viewModel.selectedImages.removeAll()
                        }
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button(action: { viewModel.removeImage(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: { viewModel.analyzeImages() }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Analyze \(viewModel.selectedImages.count) Images")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pgSecondary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Analyzing Section
    
    private var analyzingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pgAccent)
            
            Text("Analyzing medications with AI...")
                .font(.headline)
                .foregroundColor(.lightText)
            
            Text("This may take a moment")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Review Section
    
    private var reviewSection: some View {
        VStack(spacing: 20) {
            // Header with name input
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text("Review Schedule")
                        .font(.title2.bold())
                        .foregroundColor(.lightText)
                    
                    Spacer()
                }
                
                TextField("Schedule Name (e.g., Patient Name)", text: $viewModel.scheduleName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                HStack {
                    Button("Cancel") {
                        viewModel.resetFlow()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Approve") {
                        viewModel.approveSchedule()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
            )
            .padding(.horizontal)
            
            // Warnings
            if let result = viewModel.analysisResult, !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Clinical Alerts")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    ForEach(result.warnings) { warning in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(warning.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal)
            }
            
            // Medications and Schedule
            if let result = viewModel.analysisResult {
                ReconciliationMedicationList(medications: result.medications)
                    .padding(.horizontal)
                
                ReconciliationScheduleView(
                    schedule: result.schedule,
                    medications: result.medications,
                    isEditable: true,
                    onMove: { medId, from, to in
                        viewModel.moveMedication(id: medId, from: from, to: to)
                    }
                )
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Approved Section
    
    private var approvedSection: some View {
        VStack(spacing: 20) {
            // Success Banner
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Schedule Approved")
                    .font(.title.bold())
                    .foregroundColor(.lightText)
                
                Text("for \(viewModel.scheduleName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Language Picker
                HStack {
                    Text("Language:")
                        .foregroundColor(.secondary)
                    
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("Chinese").tag("Chinese (Simplified)")
                        Text("French").tag("French")
                        Text("German").tag("German")
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(Color.cardBackground.opacity(0.5))
                .cornerRadius(12)
                
                HStack(spacing: 12) {
                    Button(action: { viewModel.exportToPDF() }) {
                        Label("Export PDF", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: { viewModel.resetFlow() }) {
                        Label("New Scan", systemImage: "plus.circle")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.green.opacity(0.1))
            )
            .padding(.horizontal)
            
            // Schedule Preview
            if let result = viewModel.displayResult {
                ReconciliationScheduleView(
                    schedule: result.schedule,
                    medications: result.medications,
                    warnings: result.warnings,
                    isEditable: false,
                    scheduleName: viewModel.scheduleName,
                    labels: viewModel.translatedLabels
                )
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    MedicationReconciliationView()
}
