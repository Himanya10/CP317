//
//  RecoveryAlarmsView.swift
//  CP317-Application
//
//  Created by Himanya Verma on 2025-11-25.
//

import SwiftUI

@MainActor
struct RecoveryAlarmsView: View {
    @ObservedObject var aiModel = PredictionEngine.shared
    @State private var selectedHydrationIndex: Int?
    
    var alarms: PredictionEngine.RecoveryAlarmSet {
        aiModel.cachedAlarms ?? PredictionEngine.RecoveryAlarmSet(
            bestWakeUpTime: "7:00 AM",
            breakRecommendation: "Take a 5-minute movement break every hour.",
            hydrationSchedule: ["10:00 AM", "12:00 PM", "3:00 PM"],
            sleepRecommendation: "Target 8 hours of sleep for optimal recovery."
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                Text("Recovery Plan")
                    .font(.largeTitle.bold())
                    .foregroundColor(.lightText)
                    .padding(.horizontal)
                
                // AI Schedule Hero Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI-Optimized Schedule")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.pgSecondary)
                                Text("Personalized for You")
                                    .font(.headline)
                                    .foregroundColor(.lightText)
                            }
                        }
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Wake Up Time Feature
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.pgAccent.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "alarm.fill")
                                .font(.title2)
                                .foregroundColor(.pgAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Optimal Wake Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(alarms.bestWakeUpTime)
                                .font(.title.bold())
                                .foregroundColor(.lightText)
                        }
                        
                        Spacer()
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal)
                
                // Sleep Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.purple)
                        Text("Sleep Optimization")
                            .font(.headline)
                            .foregroundColor(.lightText)
                    }
                    
                    Text(alarms.sleepRecommendation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    // Sleep tips
                    VStack(spacing: 12) {
                        SleepTipRow(
                            icon: "bed.double.fill",
                            tip: "Maintain consistent sleep schedule"
                        )
                        SleepTipRow(
                            icon: "moon.fill",
                            tip: "Dim lights 1 hour before bed"
                        )
                        SleepTipRow(
                            icon: "iphone.slash",
                            tip: "Avoid screens 30 minutes before sleep"
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Movement Breaks
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .foregroundColor(.green)
                        Text("Movement Schedule")
                            .font(.headline)
                            .foregroundColor(.lightText)
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "figure.run")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Recommendation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(alarms.breakRecommendation)
                                .font(.subheadline)
                                .foregroundColor(.lightText)
                        }
                        
                        Spacer()
                    }
                    
                    // Quick movement suggestions
                    VStack(spacing: 8) {
                        MovementSuggestion(activity: "Stretch", duration: "2-3 min")
                        MovementSuggestion(activity: "Walk", duration: "5 min")
                        MovementSuggestion(activity: "Desk exercises", duration: "3-4 min")
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Hydration Timeline
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Hydration Timeline")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("\(alarms.hydrationSchedule.count) reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(spacing: 0) {
                        ForEach(Array(alarms.hydrationSchedule.enumerated()), id: \.offset) { index, time in
                            HydrationTimelineRow(
                                time: time,
                                isFirst: index == 0,
                                isLast: index == alarms.hydrationSchedule.count - 1,
                                isSelected: selectedHydrationIndex == index
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedHydrationIndex = index
                                }
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
                
                // Daily Recovery Checklist
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.pgAccent)
                        Text("Recovery Checklist")
                            .font(.headline)
                            .foregroundColor(.lightText)
                    }
                    
                    ChecklistItem(icon: "bed.double.fill", text: "Get 8 hours of sleep", color: .purple)
                    ChecklistItem(icon: "drop.fill", text: "Drink 8 glasses of water", color: .blue)
                    ChecklistItem(icon: "figure.walk", text: "Take movement breaks", color: .green)
                    ChecklistItem(icon: "leaf.fill", text: "Practice relaxation", color: .pgAccent)
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
    }
}

// MARK: - Supporting Components

struct SleepTipRow: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct MovementSuggestion: View {
    let activity: String
    let duration: String
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(activity)
                    .font(.subheadline)
                    .foregroundColor(.lightText)
            }
            
            Spacer()
            
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

struct HydrationTimelineRow: View {
    let time: String
    let isFirst: Bool
    let isLast: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            .frame(width: 12)
            
            // Time and content
            HStack {
                Text(time)
                    .font(isSelected ? .subheadline.bold() : .subheadline)
                    .foregroundColor(isSelected ? .blue : .lightText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            )
        }
    }
}

struct ChecklistItem: View {
    let icon: String
    let text: String
    let color: Color
    @State private var isChecked = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring()) {
                    isChecked.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(color)
                    }
                }
            }
            
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isChecked ? .secondary : .lightText)
                .strikethrough(isChecked)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecoveryAlarmsView()
        .environmentObject(PredictionEngine.shared)
}
