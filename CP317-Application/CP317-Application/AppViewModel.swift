//
//  AppViewModel.swift
//  CP317-Application
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    static let shared = AppViewModel()
    
    // Dependencies
    private let healthManager = HealthManager.shared
    private let aiModel = PredictionEngine.shared
    
    // MARK: - Original Published Properties
    @Published var isHealthKitAuthorized = false
    @Published var stepsToday: Int = 0
    @Published var stepsGoal: Int = 8000
    @Published var sleepHoursToday: Double = 0.0
    @Published var currentHeartRate: Int = 0
    
    // MARK: - New Health Metrics
    @Published var bloodPressure: String = "Not enough info"
    @Published var oxygenSaturation: String = "Not enough info"
    @Published var bodyTemperature: String = "Not enough info"
    @Published var activeCalories: Int = 0
    @Published var totalCalories: Int = 0
    @Published var distanceWalked: Double = 0.0
    @Published var workoutMinutes: Int = 0
    
    // Data availability flags
    @Published var hasBloodPressureData: Bool = false
    @Published var hasOxygenData: Bool = false
    @Published var hasTemperatureData: Bool = false
    
    // Loading states
    @Published var isLoadingHealth = false
    @Published var isLoadingPredictions = false
    @Published var lastError: String?
    
    // AI Data properties
    @Published var stressForecastScore: Double = 0.0
    @Published var optimalRestTimeString: String = "--:--"
    @Published var aiInsightText: String = "Gathering health metrics..."
    
    // Mock Data for Weekly Report Chart
    @Published var weekStress: [Double] = [0.2, 0.3, 0.45, 0.35, 0.25, 0.2, 0.15]
    
    // Debouncing
    private var fetchTask: Task<Void, Never>?
    private let fetchDebounceInterval: TimeInterval = 2.0

    private init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        healthManager.requestAuthorization { [weak self] success in
            guard let self = self else { return }
            self.isHealthKitAuthorized = success
            if success { self.requestDataAndPredictions() }
        }
    }
    
    /// The main data flow: Fetch HealthKit data, then request AI predictions.
    func requestDataAndPredictions() {
        // Cancel previous task for debouncing
        fetchTask?.cancel()
        
        fetchTask = Task { @MainActor in
            // Add delay for debouncing
            try? await Task.sleep(nanoseconds: UInt64(fetchDebounceInterval * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            isLoadingHealth = true
            lastError = nil
            
            healthManager.fetchLatestMetrics { [weak self] healthData in
                guard let self = self else { return }
                
                // Map original HealthData to UI
                self.stepsToday = healthData.stepCount
                self.sleepHoursToday = healthData.sleepHours
                self.currentHeartRate = healthData.latestHeartRate
                
                // Map new metrics to UI
                self.bloodPressure = healthData.bloodPressureString
                self.oxygenSaturation = healthData.oxygenSaturationString
                self.bodyTemperature = healthData.bodyTemperatureString
                self.activeCalories = healthData.activeCalories
                self.totalCalories = healthData.totalCalories
                self.distanceWalked = healthData.distanceWalked
                self.workoutMinutes = healthData.workoutMinutes
                
                // Update availability flags
                self.hasBloodPressureData = healthData.hasBloodPressure
                self.hasOxygenData = healthData.hasOxygenSaturation
                self.hasTemperatureData = healthData.hasBodyTemperature
                
                self.isLoadingHealth = false
                
                // Pass full data to AI
                Task {
                    self.isLoadingPredictions = true
                    await self.aiModel.requestPredictionsFromGemini(healthData: healthData)
                    self.syncAIPredictions()
                    self.isLoadingPredictions = false
                }
            }
        }
    }
    
    /// Syncs data from PredictionEngine's cache to AppViewModel's published properties.
    private func syncAIPredictions() {
        if let stress = aiModel.cachedStress {
            self.stressForecastScore = stress.predictedStressScore
            self.optimalRestTimeString = stress.optimalRestTime
        }
        
        if let goals = aiModel.cachedGoals {
            self.stepsGoal = goals.stepGoal
            self.aiInsightText = goals.recoveryNote
        }
    }
    
    var isStressHigh: Bool { stressForecastScore > 60.0 }
    
    // MARK: - Formatted Strings for Display
    
    var distanceString: String {
        String(format: "%.2f km", distanceWalked)
    }
    
    var activeCaloriesString: String {
        "\(activeCalories) cal"
    }
    
    var totalCaloriesString: String {
        "\(totalCalories) cal"
    }
    
    var workoutTimeString: String {
        if workoutMinutes == 0 {
            return "No workouts today"
        } else if workoutMinutes < 60 {
            return "\(workoutMinutes) min"
        } else {
            let hours = workoutMinutes / 60
            let mins = workoutMinutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    // MARK: - Preview Helper
    static var preview: AppViewModel {
        let vm = AppViewModel.shared
        vm.stepsToday = 5432
        vm.stepsGoal = 8000
        vm.sleepHoursToday = 7.5
        vm.currentHeartRate = 72
        vm.stressForecastScore = 45.0
        vm.optimalRestTimeString = "10:00 PM"
        vm.aiInsightText = "Your stress levels are moderate today. Consider taking breaks."
        
        // New metrics preview data
        vm.bloodPressure = "120/80"
        vm.oxygenSaturation = "98.5%"
        vm.bodyTemperature = "98.6°F"
        vm.activeCalories = 450
        vm.totalCalories = 1850
        vm.distanceWalked = 5.2
        vm.workoutMinutes = 35
        vm.hasBloodPressureData = true
        vm.hasOxygenData = true
        vm.hasTemperatureData = true
        
        return vm
    }
    // Add this to AppViewModel.swift

    var consumedCalories: Int {
        CalorieDataManager.shared.todaysCalories
    }

    var calorieGoal: Int {
        CalorieDataManager.shared.dailyGoal
    }
}
