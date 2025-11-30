//
//  MoodDataManager.swift
//  CP317-Application
//

import Foundation
import SwiftUI

@MainActor
class MoodDataManager: ObservableObject {
    static let shared = MoodDataManager()
    
    @Published var recentMoodEntries: [MoodEntry] = []
    @Published var latestMood: MoodEntry?
    
    struct MoodEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let mood: String
        let energyLevel: Double
        let stressLevel: Double
        let notes: String
        
        var stressContribution: Double {
            let moodStress: Double
            switch mood {
            case "veryHappy": moodStress = 0.1
            case "happy": moodStress = 0.2
            case "neutral": moodStress = 0.5
            case "sad": moodStress = 0.7
            case "verySad": moodStress = 0.9
            default: moodStress = 0.5
            }
            
            let energyStress = (6.0 - energyLevel) / 5.0
            let reportedStress = stressLevel / 5.0
            
            return (moodStress * 0.3 + energyStress * 0.3 + reportedStress * 0.4)
        }
        
        init(id: UUID = UUID(), timestamp: Date = Date(), mood: String, energyLevel: Double, stressLevel: Double, notes: String) {
            self.id = id
            self.timestamp = timestamp
            self.mood = mood
            self.energyLevel = energyLevel
            self.stressLevel = stressLevel
            self.notes = notes
        }
    }
    
    private init() {
        loadMoodData()
    }
    
    func logMood(mood: String, energyLevel: Double, stressLevel: Double, notes: String) {
        let entry = MoodEntry(
            mood: mood,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            notes: notes
        )
        
        recentMoodEntries.insert(entry, at: 0)
        latestMood = entry
        
        if recentMoodEntries.count > 30 {
            recentMoodEntries = Array(recentMoodEntries.prefix(30))
        }
        
        saveMoodData()
    }
    
    func getRecentMoodStress() -> Double {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = recentMoodEntries.filter { $0.timestamp >= sevenDaysAgo }
        
        guard !recentEntries.isEmpty else { return 0.5 }
        
        let totalStress = recentEntries.map { $0.stressContribution }.reduce(0, +)
        return totalStress / Double(recentEntries.count)
    }
    
    func getTodaysMoodEntries() -> [MoodEntry] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return recentMoodEntries.filter { $0.timestamp >= startOfDay }
    }
    
    private func saveMoodData() {
        if let encoded = try? JSONEncoder().encode(recentMoodEntries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
    
    private func loadMoodData() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            recentMoodEntries = decoded
            latestMood = decoded.first
        }
    }
}
