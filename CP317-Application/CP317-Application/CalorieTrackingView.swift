//
//  CalorieTrackingView.swift
//  CP317-Application


import SwiftUI
import Charts

struct CalorieTrackingView: View {
    @EnvironmentObject var vm: AppViewModel
    @StateObject private var calorieManager = CalorieDataManager.shared
    @State private var showingMealLog = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingGoalSheet = false
    @State private var showingMealDetails = false
    @State private var selectedMealTypeForDetails: MealType?
    @State private var showingFoodScanner = false  // NEW for AI Scanner
    
    enum MealType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snacks = "Snacks"
        
        var icon: String {
            switch self {
            case .breakfast: return "sun.horizon.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snacks: return "leaf.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snacks: return .green
            }
        }
    }
    
    var progress: Double {
        Double(calorieManager.todaysCalories) / Double(calorieManager.dailyGoal)
    }
    
    var remainingCalories: Int {
        calorieManager.dailyGoal - calorieManager.todaysCalories
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                HStack {
                    Text("Calorie Tracking")
                        .font(.largeTitle.bold())
                        .foregroundColor(.lightText)
                    
                    Spacer()
                    
                    Button(action: { showingGoalSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.pgAccent)
                    }
                }
                .padding(.horizontal)
                
                // Main Calorie Card
                VStack(spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Intake")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(calorieManager.todaysCalories)")
                                    .font(.system(size: 56, weight: .black))
                                    .foregroundColor(progress > 1.0 ? .red : .pgAccent)
                                
                                Text("/ \(calorieManager.dailyGoal)")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Circular Progress
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 10)
                            
                            Circle()
                                .trim(from: 0, to: min(progress, 1.0))
                                .stroke(
                                    progress > 1.0 ? Color.red : Color.pgAccent,
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: progress)
                            
                            VStack(spacing: 2) {
                                Text("\(Int(min(progress, 1.0) * 100))%")
                                    .font(.title3.bold())
                                    .foregroundColor(.lightText)
                                
                                if remainingCalories > 0 {
                                    Text("\(remainingCalories)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("left")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Over")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                    Text("by \(abs(remainingCalories))")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .frame(width: 90, height: 90)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Calorie Breakdown
                    HStack(spacing: 16) {
                        CalorieMetric(
                            icon: "flame.fill",
                            title: "Active",
                            value: vm.activeCalories,
                            color: .orange
                        )
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.2))
                        
                        CalorieMetric(
                            icon: "fork.knife",
                            title: "Consumed",
                            value: calorieManager.todaysCalories,
                            color: .pgAccent
                        )
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.2))
                        
                        CalorieMetric(
                            icon: "figure.walk",
                            title: "Burned",
                            value: vm.totalCalories,
                            color: .green
                        )
                    }
                }
                .padding(24)
                .elevatedCardStyle()
                .padding(.horizontal)
                
                // AI Food Scanner Button - NEW SECTION
                Button(action: { showingFoodScanner = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pgPrimary, Color.pgSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "camera.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("AI Food Scanner")
                                    .font(.headline)
                            }
                            .foregroundColor(.lightText)
                            
                            Text("Snap a photo to estimate calories instantly")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.pgAccent)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.pgSecondary.opacity(0.15),
                                        Color.pgPrimary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.pgSecondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal)
                
                // Meal Tracking
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Log")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            MealButton(
                                meal: meal,
                                caloriesLogged: calorieManager.getCaloriesForMealType(meal.rawValue)
                            ) {
                                selectedMealType = meal
                                showingMealLog = true
                            } onLongPress: {
                                selectedMealTypeForDetails = meal
                                showingMealDetails = true
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Today's Meals List
                if !calorieManager.todaysMeals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Meals")
                                .font(.headline)
                                .foregroundColor(.lightText)
                            
                            Spacer()
                            
                            Button(action: {
                                calorieManager.clearTodaysMeals()
                            }) {
                                Text("Clear All")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        ForEach(calorieManager.todaysMeals) { meal in
                            MealEntryRow(meal: meal) {
                                calorieManager.deleteMeal(meal)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)
                }
                
                // Weekly Calorie Chart
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    Chart {
                        ForEach(calorieManager.getWeeklyData()) { data in
                            BarMark(
                                x: .value("Day", data.dayString),
                                y: .value("Calories", data.totalCalories)
                            )
                            .foregroundStyle(Color.pgAccent.gradient)
                            
                            RuleMark(y: .value("Goal", calorieManager.dailyGoal))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .foregroundStyle(.green.opacity(0.5))
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...max(calorieManager.dailyGoal + 500, 3000))
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.pgAccent)
                        Text("Average: \(calorieManager.getAverageCalories()) kcal/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Nutrition Tips
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Nutrition Tips")
                            .font(.headline)
                            .foregroundColor(.lightText)
                    }
                    
                    if calorieManager.todaysCalories < calorieManager.dailyGoal * 80 / 100 {
                        NutritionTip(
                            icon: "arrow.up.circle.fill",
                            text: "You're below your calorie goal. Make sure you're eating enough to fuel your activities.",
                            color: .orange
                        )
                    } else if calorieManager.todaysCalories > calorieManager.dailyGoal {
                        NutritionTip(
                            icon: "exclamationmark.triangle.fill",
                            text: "You've exceeded your calorie goal. Consider lighter options for your next meal.",
                            color: .red
                        )
                    } else {
                        NutritionTip(
                            icon: "checkmark.circle.fill",
                            text: "Great job! You're on track with your calorie goals today.",
                            color: .green
                        )
                    }
                    
                    NutritionTip(
                        icon: "drop.fill",
                        text: "Stay hydrated! Aim for 8 glasses of water throughout the day.",
                        color: .blue
                    )
                    
                    NutritionTip(
                        icon: "leaf.fill",
                        text: "Include protein, healthy fats, and fiber in each meal for sustained energy.",
                        color: .green
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .background(Color.darkBackground.ignoresSafeArea())
        .sheet(isPresented: $showingMealLog) {
            MealLogSheet(mealType: selectedMealType, calorieManager: calorieManager)
        }
        .sheet(isPresented: $showingGoalSheet) {
            CalorieGoalSheet(calorieManager: calorieManager)
        }
        .sheet(isPresented: $showingMealDetails) {
            if let mealType = selectedMealTypeForDetails {
                MealDetailsSheet(mealType: mealType, calorieManager: calorieManager)
            }
        }
        .fullScreenCover(isPresented: $showingFoodScanner) {
            FoodChatView()
        }
    }
}

// MARK: - Supporting Components (Keep all existing components)

struct CalorieMetric: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(value)")
                    .font(.subheadline.bold())
                    .foregroundColor(.lightText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealButton: View {
    let meal: CalorieTrackingView.MealType
    let caloriesLogged: Int
    let action: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(meal.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: meal.icon)
                        .font(.title2)
                        .foregroundColor(meal.color)
                }
                
                Text(meal.rawValue)
                    .font(.subheadline.bold())
                    .foregroundColor(.lightText)
                
                if caloriesLogged > 0 {
                    Text("\(caloriesLogged) kcal")
                        .font(.caption)
                        .foregroundColor(meal.color)
                } else {
                    Text("Log meal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(caloriesLogged > 0 ? meal.color.opacity(0.1) : Color.cardBackground.opacity(0.6))
            )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

struct MealEntryRow: View {
    let meal: CalorieDataManager.MealEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.subheadline.bold())
                    .foregroundColor(.lightText)
                
                HStack(spacing: 8) {
                    Text(meal.mealType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.pgAccent.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(meal.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(meal.calories) kcal")
                .font(.subheadline.bold())
                .foregroundColor(.pgAccent)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground.opacity(0.5))
        )
    }
}

struct NutritionTip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Meal Log Sheet

struct MealLogSheet: View {
    let mealType: CalorieTrackingView.MealType
    @ObservedObject var calorieManager: CalorieDataManager
    @Environment(\.dismiss) var dismiss
    @State private var foodName = ""
    @State private var calories = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    HStack {
                        Image(systemName: mealType.icon)
                            .foregroundColor(mealType.color)
                        Text(mealType.rawValue)
                            .font(.headline)
                    }
                }
                
                Section("Food Information") {
                    TextField("Food name (e.g., Chicken Salad)", text: $foodName)
                    
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: logMeal) {
                        HStack {
                            Spacer()
                            if showingSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Logged!")
                                }
                                .foregroundColor(.green)
                            } else {
                                Text("Log Meal")
                                    .foregroundColor(.pgAccent)
                            }
                            Spacer()
                        }
                    }
                    .disabled(foodName.isEmpty || calories.isEmpty || showingSuccess)
                }
            }
            .navigationTitle("Log \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func logMeal() {
        guard let calorieAmount = Int(calories) else { return }
        
        calorieManager.addMeal(
            mealType: mealType.rawValue,
            foodName: foodName,
            calories: calorieAmount
        )
        
        withAnimation {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// MARK: - Meal Details Sheet

struct MealDetailsSheet: View {
    let mealType: CalorieTrackingView.MealType
    @ObservedObject var calorieManager: CalorieDataManager
    @Environment(\.dismiss) var dismiss
    
    var meals: [CalorieDataManager.MealEntry] {
        calorieManager.getMealsForMealType(mealType.rawValue)
    }
    
    var totalCalories: Int {
        calorieManager.getCaloriesForMealType(mealType.rawValue)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: mealType.icon)
                            .foregroundColor(mealType.color)
                        Text(mealType.rawValue)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(totalCalories) kcal")
                            .font(.headline)
                            .foregroundColor(mealType.color)
                    }
                }
                
                if meals.isEmpty {
                    Section {
                        Text("No meals logged yet")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } else {
                    Section("Logged Items") {
                        ForEach(meals) { meal in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.foodName)
                                        .font(.subheadline)
                                    Text(meal.date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(meal.calories) kcal")
                                    .font(.subheadline.bold())
                                    .foregroundColor(mealType.color)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                calorieManager.deleteMeal(meals[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(mealType.rawValue) Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Calorie Goal Sheet

struct CalorieGoalSheet: View {
    @ObservedObject var calorieManager: CalorieDataManager
    @Environment(\.dismiss) var dismiss
    @State private var tempGoal: Double
    
    init(calorieManager: CalorieDataManager) {
        self.calorieManager = calorieManager
        self._tempGoal = State(initialValue: Double(calorieManager.dailyGoal))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Calorie Goal") {
                    VStack(spacing: 16) {
                        Text("\(Int(tempGoal)) kcal")
                            .font(.largeTitle.bold())
                            .foregroundColor(.pgAccent)
                        
                        Slider(value: $tempGoal, in: 0...5000, step: 50)
                            .tint(.pgAccent)
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("5000")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Recommendations") {
                    Text("Based on your activity level and goals, a typical daily calorie intake ranges from 1,800 to 2,500 kcal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Save Goal") {
                        calorieManager.updateGoal(Int(tempGoal))
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.pgAccent)
                }
            }
            .navigationTitle("Set Calorie Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CalorieTrackingView()
        .environmentObject(AppViewModel.preview)
}
