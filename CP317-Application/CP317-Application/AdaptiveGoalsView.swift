//
//  AdaptiveGoalsView.swift
//  CP317-Application
//

import SwiftUI

struct AdaptiveGoalsView: View {
    @EnvironmentObject var aiModel: PredictionEngine
    @EnvironmentObject var vm: AppViewModel
    
    var todaysGoal: Int { aiModel.cachedGoals?.stepGoal ?? 8000 }
    var stepsSoFar: Int { vm.stepsToday }
    var recoveryNote: String { aiModel.cachedGoals?.recoveryNote ?? "Goal is based on standard daily recommendations until AI data is available." }
    
    var progress: Double {
        Double(stepsSoFar) / Double(todaysGoal)
    }
    
    var goalStatus: (text: String, color: Color) {
        switch progress {
        case 1.0...: return ("Achieved! 🎉", .green)
        case 0.75..<1.0: return ("Almost there!", .yellow)
        case 0.5..<0.75: return ("Making progress", .orange)
        default: return ("Let's move!", .red)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Adaptive Goals")
                    .font(.largeTitle.bold())
                    .foregroundColor(.lightText)
                    .padding(.horizontal)
                
                // Goal Progress Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Step Goal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(stepsSoFar)")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundColor(.pgAccent)
                                
                                Text("/ \(todaysGoal)")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Circle()
                                    .fill(goalStatus.color)
                                    .frame(width: 8, height: 8)
                                Text(goalStatus.text)
                                    .font(.subheadline.bold())
                                    .foregroundColor(goalStatus.color)
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        // Circular Progress
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 10)
                            
                            Circle()
                                .trim(from: 0, to: min(progress, 1.0))
                                .stroke(goalStatus.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: progress)
                            
                            Text("\(Int(min(progress, 1.0) * 100))%")
                                .font(.title3.bold())
                                .foregroundColor(.lightText)
                        }
                        .frame(width: 90, height: 90)
                    }
                    
                    // Linear Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: min(progress, 1.0))
                            .tint(goalStatus.color)
                            .scaleEffect(y: 2)
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(todaysGoal)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // AI Recovery Note
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.pgSecondary)
                            Text("AI Recommendation")
                                .font(.headline)
                                .foregroundColor(.lightText)
                        }
                        
                        Text(recoveryNote)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal)
                
                // AI Adjustment Factors
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Adjustment Factors")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    AdjustmentFactorRow(
                        icon: "brain.head.profile",
                        label: "Fatigue Level",
                        value: aiModel.cachedGoals?.recoveryNote.contains("fatigue") == true ? "High" : "Low",
                        color: aiModel.cachedGoals?.recoveryNote.contains("fatigue") == true ? .orange : .green
                    )
                    
                    AdjustmentFactorRow(
                        icon: "bed.double.fill",
                        label: "Sleep Quality",
                        value: vm.sleepHoursToday >= 7 ? "Good" : "Needs Improvement",
                        color: vm.sleepHoursToday >= 7 ? .green : .orange
                    )
                    
                    AdjustmentFactorRow(
                        icon: "figure.walk",
                        label: "Recovery Focus",
                        value: aiModel.cachedGoals?.recoveryNote.contains("recovery") == true ? "Active" : "Standard",
                        color: .pgAccent
                    )
                    
                    AdjustmentFactorRow(
                        icon: "heart.fill",
                        label: "Heart Rate Trend",
                        value: vm.currentHeartRate < 80 ? "Normal" : "Elevated",
                        color: vm.currentHeartRate < 80 ? .green : .orange
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Weekly Goal History
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week's Progress")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    let weekProgress = [0.92, 1.05, 0.88, 0.95, 1.12, 0.78, 0.65]
                    
                    HStack(spacing: 8) {
                        ForEach(Array(zip(weekDays, weekProgress)), id: \.0) { day, progress in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 44)
                                    
                                    if progress >= 1.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    } else {
                                        Text("\(Int(progress * 100))%")
                                            .font(.caption2.bold())
                                            .foregroundColor(progress > 0.8 ? .yellow : .secondary)
                                    }
                                }
                                
                                Text(day)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
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
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .background(Color.darkBackground.ignoresSafeArea())
    }
}

struct AdjustmentFactorRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.lightText)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AdaptiveGoalsView()
        .environmentObject(AppViewModel.preview)
        .environmentObject(PredictionEngine.shared)
}
