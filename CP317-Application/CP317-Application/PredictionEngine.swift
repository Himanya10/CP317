//
//  PredictionEngine.swift
//  CP317-Application
//

import Foundation

@MainActor
final class PredictionEngine: ObservableObject {
    // MARK: - Singleton
    static let shared = PredictionEngine()
    private init() {}

    // MARK: - Prediction Models
    
    struct StressContributors: Codable {
        let sleepImpact: Double
        let heartRateImpact: Double
        let activityImpact: Double
        let moodImpact: Double
        let hrvImpact: Double
    }
    
    struct StressPrediction: Codable {
        let predictedStressScore: Double    // 0..100
        let burnoutRisk: Double             // 0..1 (changed from 0..100 for consistency)
        let optimalRestTime: String         // e.g. "9:30 PM"
        let confidence: Double              // 0..1
        let contributors: StressContributors // Added this property
    }

    struct EmotionInsights: Codable {
        let dominantEmotion: String
        let tensionLevel: Double            // 0..1
        let energyLevel: Double             // 0..1
        let explanation: String
    }

    struct AdaptiveGoals: Codable {
        let stepGoal: Int
        let movementMinutes: Int
        let recoveryNote: String
    }

    struct RecoveryAlarmSet: Codable {
        let bestWakeUpTime: String
        let breakRecommendation: String
        let hydrationSchedule: [String]
        let sleepRecommendation: String
    }

    // MARK: - Observable cached predictions
    @Published var cachedStress: StressPrediction?
    @Published var cachedEmotion: EmotionInsights?
    @Published var cachedGoals: AdaptiveGoals?
    @Published var cachedAlarms: RecoveryAlarmSet?
    @Published var lastErrorMessage: String?

    // MARK: - Core Inference Functions
    
    private func predictStress(hrv: Double, sleepHours: Double, steps: Int, heartRate: Int) -> StressPrediction {
        // Heuristic-based stress calculation:
        // 1. HRV Penalty: Lower HRV indicates higher stress
        // 2. Sleep Penalty: Less than 8 hours increases stress
        // 3. Steps Score: Higher activity can indicate either stress or good health
        // 4. Heart Rate Penalty: Elevated HR (>75) suggests stress
        
        let hrvScore = max(0, (100.0 - hrv) * 1.5)
        let sleepScore = max(0, (8.0 - sleepHours) * 10.0)
        let stepsScore = Double(steps) / 200.0
        let hrPenalty = max(0.0, Double(heartRate - 75)) * 2.5
        
        let rawScore = hrvScore + sleepScore - stepsScore + hrPenalty
        let stressScore = min(100.0, max(0.0, rawScore * 0.5))
        
        // Burnout risk as 0..1 (not 0..100)
        let burnoutRisk = min(1.0, stressScore / 80.0)
        
        // Calculate optimal rest time
        let hoursUntilRest = max(1.0, 24.0 - sleepHours + 8.0)
        let restTime = Calendar.current.date(byAdding: .hour, value: -Int(hoursUntilRest), to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        // Calculate individual contributors (normalized to 0..1)
        let sleepImpact = min(1.0, sleepScore / 100.0)
        let heartRateImpact = min(1.0, hrPenalty / 100.0)
        let hrvImpact = min(1.0, hrvScore / 150.0)
        let activityImpact = 1.0 - min(1.0, Double(steps) / 10000.0)
        let moodImpact = 0.3 // Default/placeholder - could be enhanced with actual mood data
        
        let contributors = StressContributors(
            sleepImpact: sleepImpact,
            heartRateImpact: heartRateImpact,
            activityImpact: activityImpact,
            moodImpact: moodImpact,
            hrvImpact: hrvImpact
        )
        
        return StressPrediction(
            predictedStressScore: stressScore,
            burnoutRisk: burnoutRisk,
            optimalRestTime: formatter.string(from: restTime),
            confidence: 0.85,
            contributors: contributors
        )
    }

    private func analyzeEmotions(hrSpikes: Int, movement: Double, sleepDebt: Double) -> EmotionInsights {
        let tension = min(1.0, (Double(hrSpikes) * 0.1) + (sleepDebt * 0.15))
        let energy = min(1.0, max(0.0, movement * 0.5 + (1.0 - tension)))
        
        // Determine dominant emotion based on tension and energy levels
        let emotion: String
        if tension > 0.6 {
            emotion = "Tension"
        } else if energy > 0.7 {
            emotion = "Vigorous"
        } else if energy < 0.3 {
            emotion = "Fatigued"
        } else {
            emotion = "Calm"
        }
        
        // Generate contextual explanation
        let explanation: String
        if sleepDebt > 1.5 {
            explanation = "Sleep debt is affecting your emotional state. Consider prioritizing rest."
        } else if movement > 0.8 {
            explanation = "High activity levels detected. You're maintaining good energy throughout the day."
        } else {
            explanation = "Based on your recent activity and sleep patterns, you're maintaining emotional balance."
        }

        return EmotionInsights(
            dominantEmotion: emotion,
            tensionLevel: tension,
            energyLevel: energy,
            explanation: explanation
        )
    }

    private func generateAdaptiveGoals(yesterdayFatigue: Double, sleepQuality: Double, todaysPerformance: Double) -> AdaptiveGoals {
        var baseGoal = 8000
        var recoveryNote = "Goal optimized for today's energy levels."
        
        // Adjust goal based on recovery indicators
        if sleepQuality < 0.5 {
            baseGoal = 5000
            recoveryNote = "Step goal significantly lowered due to poor sleep. Prioritize recovery today."
        } else if sleepQuality < 0.7 {
            baseGoal = 6000
            recoveryNote = "Step goal lowered due to suboptimal sleep. Focus on gentle movement and recovery."
        } else if yesterdayFatigue > 0.7 {
            baseGoal = 7000
            recoveryNote = "Moderate goal set to allow for recovery from yesterday's fatigue."
        } else if todaysPerformance > 0.8 {
            baseGoal = 10000
            recoveryNote = "You're performing well! Goal increased to challenge you today."
        } else if todaysPerformance > 0.5 {
            baseGoal = 9000
            recoveryNote = "Good energy levels detected. Slightly elevated goal for today."
        }
        
        return AdaptiveGoals(
            stepGoal: baseGoal,
            movementMinutes: Int(Double(baseGoal) / 100),
            recoveryNote: recoveryNote
        )
    }

    private func generateRecoveryAlarms(sleepHours: Double, hrv: Double) -> RecoveryAlarmSet {
        // Calculate optimal wake time based on sleep deficit
        let sleepDeficit = max(0, 8.0 - sleepHours)
        let wakeHour = min(9, 7 + Int(sleepDeficit))
        let bestWakeUpTime = "\(wakeHour):30 AM"
        
        // Customize recommendations based on HRV
        let sleepRecommendation: String
        if hrv < 40 {
            sleepRecommendation = "Your HRV is low. Prioritize 8+ hours of sleep tonight and consider relaxation techniques."
        } else if hrv < 60 {
            sleepRecommendation = "Aim for 8 hours of sleep to improve recovery."
        } else {
            sleepRecommendation = "Maintain current sleep schedule. Your recovery is on track."
        }
        
        return RecoveryAlarmSet(
            bestWakeUpTime: bestWakeUpTime,
            breakRecommendation: "Take a 5-minute movement break every hour.",
            hydrationSchedule: ["10:00 AM", "2:00 PM", "5:00 PM"],
            sleepRecommendation: sleepRecommendation
        )
    }

    // MARK: - Sync Methods

    @MainActor
    func syncHealthData(hrv: Double, sleepMinutes: Double, steps: Int, heartRate: Int, recentPatternScore: Double) {
        let sleepHours = sleepMinutes / 60.0
        let sleepDebt = max(0.0, 8.0 - sleepHours)

        let stress = predictStress(hrv: hrv, sleepHours: sleepHours, steps: steps, heartRate: heartRate)
        let emotions = analyzeEmotions(
            hrSpikes: Int(recentPatternScore * 10),
            movement: Double(steps) / 10000.0,
            sleepDebt: sleepDebt
        )
        let adaptive = generateAdaptiveGoals(
            yesterdayFatigue: recentPatternScore,
            sleepQuality: min(1.0, sleepHours / 8.0),
            todaysPerformance: Double(steps) / 10000.0
        )
        let alarms = generateRecoveryAlarms(sleepHours: sleepHours, hrv: hrv)

        self.cachedStress = stress
        self.cachedEmotion = emotions
        self.cachedGoals = adaptive
        self.cachedAlarms = alarms
    }

    // Main entry point called by AppViewModel
    func requestPredictionsFromGemini(healthData: HealthData) async {
        let recentPatternScore = 0.6 // Mock pattern score - could be calculated from historical data
        
        syncHealthData(
            hrv: healthData.hrvSDNN,
            sleepMinutes: healthData.sleepHours * 60.0,
            steps: healthData.stepCount,
            heartRate: healthData.averageHeartRate,
            recentPatternScore: recentPatternScore
        )
    }
}
