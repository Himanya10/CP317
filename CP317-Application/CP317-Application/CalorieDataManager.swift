//
//  CalorieDataManager.swift
//  CP317-Application
//

import Foundation
import SwiftUI

@MainActor
class CalorieDataManager: ObservableObject {
    static let shared = CalorieDataManager()
    
    @Published var dailyGoal: Int = 2000
    @Published var meals: [MealEntry] = []
    @Published var weeklyHistory: [DayCalories] = []
    
    struct MealEntry: Identifiable, Codable {
        let id: UUID
        let date: Date
        let mealType: String
        let foodName: String
        let calories: Int
        
        var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }
        
        init(id: UUID = UUID(), date: Date = Date(), mealType: String, foodName: String, calories: Int) {
            self.id = id
            self.date = date
            self.mealType = mealType
            self.foodName = foodName
            self.calories = calories
        }
    }
    
    struct DayCalories: Identifiable, Codable {
        let id: UUID
        let date: Date
        let totalCalories: Int
        
        var dayString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
        
        init(id: UUID = UUID(), date: Date, totalCalories: Int) {
            self.id = id
            self.date = date
            self.totalCalories = totalCalories
        }
    }
    
    private let mealsKey = "savedMeals"
    private let goalKey = "calorieGoal"
    private let historyKey = "weeklyCalorieHistory"
    
    private init() {
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var todaysMeals: [MealEntry] {
        meals.filter { $0.isToday }
    }
    
    var todaysCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    var caloriesByMealType: [String: Int] {
        var breakdown: [String: Int] = [:]
        for meal in todaysMeals {
            breakdown[meal.mealType, default: 0] += meal.calories
        }
        return breakdown
    }
    
    // MARK: - Data Management
    
    func addMeal(mealType: String, foodName: String, calories: Int) {
        let meal = MealEntry(mealType: mealType, foodName: foodName, calories: calories)
        meals.insert(meal, at: 0)
        saveMeals()
        updateWeeklyHistory()
    }
    
    func deleteMeal(_ meal: MealEntry) {
        meals.removeAll { $0.id == meal.id }
        saveMeals()
        updateWeeklyHistory()
    }
    
    func updateGoal(_ newGoal: Int) {
        dailyGoal = newGoal
        UserDefaults.standard.set(newGoal, forKey: goalKey)
    }
    
    func getMealsForMealType(_ mealType: String) -> [MealEntry] {
        todaysMeals.filter { $0.mealType == mealType }
    }
    
    func getCaloriesForMealType(_ mealType: String) -> Int {
        getMealsForMealType(mealType).reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - Weekly History
    
    func getWeeklyData() -> [DayCalories] {
        var weekData: [DayCalories] = []
        let calendar = Calendar.current
        
        for daysAgo in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            let dayMeals = meals.filter { $0.date >= startOfDay && $0.date < endOfDay }
            let totalCalories = dayMeals.reduce(0) { $0 + $1.calories }
            
            weekData.append(DayCalories(date: startOfDay, totalCalories: totalCalories))
        }
        
        return weekData
    }
    
    private func updateWeeklyHistory() {
        weeklyHistory = getWeeklyData()
        saveHistory()
    }
    
    // MARK: - Persistence
    
    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(encoded, forKey: mealsKey)
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(weeklyHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadData() {
        // Load goal
        let savedGoal = UserDefaults.standard.integer(forKey: goalKey)
        if savedGoal > 0 {
            dailyGoal = savedGoal
        }
        
        // Load meals
        if let data = UserDefaults.standard.data(forKey: mealsKey),
           let decoded = try? JSONDecoder().decode([MealEntry].self, from: data) {
            meals = decoded
        }
        
        // Load history
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([DayCalories].self, from: data) {
            weeklyHistory = decoded
        } else {
            updateWeeklyHistory()
        }
    }
    
    // MARK: - Helper Methods
    
    func clearTodaysMeals() {
        meals.removeAll { $0.isToday }
        saveMeals()
        updateWeeklyHistory()
    }
    
    func getAverageCalories() -> Int {
        let weekData = getWeeklyData()
        guard !weekData.isEmpty else { return 0 }
        let total = weekData.reduce(0) { $0 + $1.totalCalories }
        return total / weekData.count
    }
}
