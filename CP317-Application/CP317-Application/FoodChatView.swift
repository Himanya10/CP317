//
//  FoodChatView.swift
//  CP317-Application
//

import SwiftUI
import PhotosUI

struct FoodChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FoodChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if viewModel.isAnalyzing {
                                    TypingIndicator()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    inputArea
                }
            }
            .navigationTitle("Food Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentAnalysis != nil {
                        Button("Save") {
                            viewModel.saveMeal()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(
                    selectedImages: $viewModel.selectedImages,
                    scanType: .bottleLabel
                )
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView(image: Binding(
                    get: { nil },
                    set: { if let img = $0 { viewModel.addImage(img) } }
                ))
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let analysis = viewModel.currentAnalysis {
                    EditNutritionSheet(
                        analysis: analysis,
                        onSave: { updated in
                            viewModel.updateAnalysis(updated)
                        }
                    )
                }
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
    
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Image Preview
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: { viewModel.removeImage(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 70)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Input Field
            HStack(spacing: 12) {
                // Camera Button
                Button(action: { viewModel.showCamera = true }) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                        .foregroundColor(.pgAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.pgAccent.opacity(0.2))
                        .clipShape(Circle())
                }
                
                // Photo Library Button
                Button(action: { viewModel.showImagePicker = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundColor(.pgAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.pgAccent.opacity(0.2))
                        .clipShape(Circle())
                }
                
                // Text Input
                TextField("Describe modifications (e.g., 'added lettuce')...", text: $viewModel.userInput)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .foregroundColor(.lightText)
                
                // Send Button
                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: viewModel.canAnalyze ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title2)
                        .foregroundColor(viewModel.canAnalyze ? .pgAccent : .secondary)
                }
                .disabled(!viewModel.canAnalyze)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - View Model

@MainActor
class FoodChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedImages: [UIImage] = []
    @Published var userInput: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var currentAnalysis: FoodAnalysisResult?
    @Published var errorMessage: String?
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var showEditSheet = false
    
    private let foodService = FoodRecognitionService.shared
    private let calorieManager = CalorieDataManager.shared
    
    var canAnalyze: Bool {
        !selectedImages.isEmpty || !userInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init() {
        // Welcome message
        messages.append(ChatMessage(
            content: "👋 Hi! I'm your AI nutrition assistant. Take a photo of your food or describe it, and I'll estimate the calories and nutritional info for you!",
            isUser: false
        ))
    }
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    func sendMessage() {
        let text = userInput.trimmingCharacters(in: .whitespaces)
        
        // Add user message
        if !text.isEmpty {
            messages.append(ChatMessage(content: text, isUser: true))
        }
        
        // Add image message if present
        if !selectedImages.isEmpty {
            messages.append(ChatMessage(content: "📷 Uploaded \(selectedImages.count) image(s)", isUser: true))
        }
        
        // Clear input
        userInput = ""
        
        // Analyze food
        Task {
            await analyzeFood(modifications: text.isEmpty ? nil : text)
        }
    }
    
    private func analyzeFood(modifications: String?) async {
        isAnalyzing = true
        
        do {
            // Use first image for analysis
            guard let image = selectedImages.first else {
                throw FoodRecognitionError.invalidImage
            }
            
            let result = try await foodService.analyzeFood(
                image: image,
                userModifications: modifications
            )
            
            currentAnalysis = result
            
            // Add AI response with analysis
            let response = formatAnalysisResponse(result)
            messages.append(ChatMessage(
                content: response,
                isUser: false,
                analysis: result
            ))
            
            // Ask follow-up
            messages.append(ChatMessage(
                content: "Does this look accurate? You can:\n• Tap 'Edit' to adjust the values\n• Tell me about any modifications\n• Tap 'Save' when you're ready to log this meal",
                isUser: false
            ))
            
        } catch {
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(
                content: "Sorry, I had trouble analyzing that. Could you try taking another photo or describing the food in more detail?",
                isUser: false
            ))
        }
        
        isAnalyzing = false
        selectedImages.removeAll()
    }
    
    private func formatAnalysisResponse(_ analysis: FoodAnalysisResult) -> String {
        var response = "🍽️ **\(analysis.foodName)**\n\n"
        response += "\(analysis.description)\n\n"
        response += "📊 **Nutritional Info**\n"
        response += "• Calories: **\(analysis.calories) kcal**\n"
        response += "• Protein: \(Int(analysis.protein))g\n"
        response += "• Carbs: \(Int(analysis.carbs))g\n"
        response += "• Fat: \(Int(analysis.fat))g\n"
        response += "• Fiber: \(Int(analysis.fiber))g\n\n"
        response += "📏 Portion: \(analysis.portionSize)\n\n"
        
        if !analysis.ingredients.isEmpty {
            response += "🥘 Ingredients: \(analysis.ingredients.prefix(5).joined(separator: ", "))\n\n"
        }
        
        if let mods = analysis.modifications, !mods.isEmpty {
            response += "✏️ Modifications: \(mods)\n\n"
        }
        
        response += "ℹ️ Confidence: \(analysis.confidencePercentage)\n"
        response += "💭 \(analysis.reasoning)"
        
        return response
    }
    
    func updateAnalysis(_ updated: FoodAnalysisResult) {
        currentAnalysis = updated
        
        // Add update message
        messages.append(ChatMessage(
            content: "✅ Updated nutrition info:\n• Calories: \(updated.calories) kcal\n• \(updated.macroBreakdown)",
            isUser: false
        ))
    }
    
    func saveMeal() {
        guard let analysis = currentAnalysis else { return }
        
        // Determine meal type based on time
        let hour = Calendar.current.component(.hour, from: Date())
        let mealType: String
        switch hour {
        case 5..<11: mealType = "Breakfast"
        case 11..<14: mealType = "Lunch"
        case 14..<17: mealType = "Snacks"
        default: mealType = "Dinner"
        }
        
        calorieManager.addMeal(
            mealType: mealType,
            foodName: analysis.foodName,
            calories: analysis.calories
        )
        
        messages.append(ChatMessage(
            content: "✅ Meal saved to your \(mealType) log!",
            isUser: false
        ))
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    let analysis: FoodAnalysisResult?
    
    init(content: String, isUser: Bool, analysis: FoodAnalysisResult? = nil) {
        self.content = content
        self.isUser = isUser
        self.analysis = analysis
    }
}

// MARK: - Supporting Views

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showEditSheet = false
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .lightText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isUser ? Color.pgAccent : Color.cardBackground)
                    )
                    .textSelection(.enabled)
                
                // Edit button for analysis messages
                if let analysis = message.analysis {
                    Button(action: { showEditSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                            Text("Edit Values")
                        }
                        .font(.caption)
                        .foregroundColor(.pgAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pgAccent.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .sheet(isPresented: $showEditSheet) {
                        EditNutritionSheet(analysis: analysis, onSave: { _ in })
                    }
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.pgAccent)
                    .frame(width: 8, height: 8)
                    .opacity(animating ? 1 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .onAppear { animating = true }
    }
}

struct EditNutritionSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var editableAnalysis: FoodAnalysisResult
    let onSave: (FoodAnalysisResult) -> Void
    
    init(analysis: FoodAnalysisResult, onSave: @escaping (FoodAnalysisResult) -> Void) {
        _editableAnalysis = State(initialValue: analysis)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    HStack {
                        Text("Food Name")
                        Spacer()
                        Text(editableAnalysis.foodName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Portion Size")
                        Spacer()
                        Text(editableAnalysis.portionSize)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Calories") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Calories", value: $editableAnalysis.calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Macronutrients") {
                    NutrientField(label: "Protein", value: $editableAnalysis.protein, unit: "g")
                    NutrientField(label: "Carbs", value: $editableAnalysis.carbs, unit: "g")
                    NutrientField(label: "Fat", value: $editableAnalysis.fat, unit: "g")
                    NutrientField(label: "Fiber", value: $editableAnalysis.fiber, unit: "g")
                }
                
                Section("AI Analysis") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence: \(editableAnalysis.confidencePercentage)")
                            .font(.subheadline)
                        
                        Text(editableAnalysis.reasoning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Nutrition Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(editableAnalysis)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct NutrientField: View {
    let label: String
    @Binding var value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FoodChatView()
}
