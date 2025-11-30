//
//  WeeklyReportView.swift
//  CP317-Application
//
//  Created by Himanya Verma on 2025-11-25.
//

import SwiftUI
import Charts

@MainActor
struct WeeklyReportView: View {
    @StateObject var vm = AppViewModel.shared
    @State private var selectedMetric: MetricType = .steps
    @State private var showExportSheet = false
    
    enum MetricType: String, CaseIterable {
        case steps = "Steps"
        case stress = "Stress"
        case sleep = "Sleep"
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .stress: return "waveform.path.ecg"
            case .sleep: return "bed.double.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .steps: return .pgAccent
            case .stress: return .orange
            case .sleep: return .purple
            }
        }
    }
    
    struct DayData: Identifiable {
        let id = UUID()
        let day: String
        let steps: Int
        let stressScore: Double
        let sleepHours: Double
        
        var stepsGoalMet: Bool { steps >= 8000 }
        var goodSleep: Bool { sleepHours >= 7.0 }
        var lowStress: Bool { stressScore < 50 }
    }
    
    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var weeklyData: [DayData] {
        let mockSteps = [8200, 10320, 6400, 9100, 7600, 12040, 4800]
        let mockSleepHours = [7.5, 8.0, 6.2, 7.8, 7.0, 9.0, 6.0]
        let safeStressData = vm.weekStress + Array(repeating: 0.5, count: max(0, 7 - vm.weekStress.count))
        
        return daysOfWeek.enumerated().map { (index, day) in
            DayData(
                day: day,
                steps: mockSteps[index % mockSteps.count],
                stressScore: safeStressData[index] * 100,
                sleepHours: mockSleepHours[index % mockSleepHours.count]
            )
        }
    }
    
    var weeklyAverages: (steps: Int, stress: Double, sleep: Double) {
        let avgSteps = weeklyData.map { $0.steps }.reduce(0, +) / weeklyData.count
        let avgStress = weeklyData.map { $0.stressScore }.reduce(0, +) / Double(weeklyData.count)
        let avgSleep = weeklyData.map { $0.sleepHours }.reduce(0, +) / Double(weeklyData.count)
        return (avgSteps, avgStress, avgSleep)
    }
    
    var achievements: [Achievement] {
        let goalsMetCount = weeklyData.filter { $0.stepsGoalMet }.count
        let goodSleepCount = weeklyData.filter { $0.goodSleep }.count
        let lowStressCount = weeklyData.filter { $0.lowStress }.count
        
        return [
            Achievement(title: "Step Goals Met", count: goalsMetCount, total: 7, icon: "figure.walk", color: .green),
            Achievement(title: "Good Sleep Nights", count: goodSleepCount, total: 7, icon: "moon.stars.fill", color: .purple),
            Achievement(title: "Low Stress Days", count: lowStressCount, total: 7, icon: "face.smiling.fill", color: .blue)
        ]
    }
    
    struct Achievement: Identifiable {
        let id = UUID()
        let title: String
        let count: Int
        let total: Int
        let icon: String
        let color: Color
        
        var percentage: Double { Double(count) / Double(total) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header with Export Button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Report")
                                .font(.largeTitle.bold())
                                .foregroundColor(.lightText)
                            
                            Text(dateRangeString())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showExportSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(.pgAccent)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Weekly Score Card
                    WeeklyScoreCard(averages: weeklyAverages)
                        .padding(.horizontal)
                    
                    // Achievement Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly Achievements")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        ForEach(achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Metric Selector and Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Trends")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(MetricType.allCases, id: \.self) { metric in
                                HStack {
                                    Image(systemName: metric.icon)
                                    Text(metric.rawValue)
                                }
                                .tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                        
                        Chart {
                            ForEach(weeklyData) { day in
                                switch selectedMetric {
                                case .steps:
                                    BarMark(
                                        x: .value("Day", day.day),
                                        y: .value("Steps", day.steps)
                                    )
                                    .foregroundStyle(Color.pgAccent.gradient)
                                    .annotation(position: .top) {
                                        if day.stepsGoalMet {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    RuleMark(y: .value("Goal", 8000))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                        .foregroundStyle(.green.opacity(0.5))
                                    
                                case .stress:
                                    BarMark(
                                        x: .value("Day", day.day),
                                        y: .value("Stress", day.stressScore)
                                    )
                                    .foregroundStyle(day.stressScore > 60 ? Color.red.gradient : Color.orange.gradient)
                                    
                                    RuleMark(y: .value("High", 60))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                        .foregroundStyle(.red.opacity(0.5))
                                    
                                case .sleep:
                                    BarMark(
                                        x: .value("Day", day.day),
                                        y: .value("Sleep", day.sleepHours)
                                    )
                                    .foregroundStyle(day.goodSleep ? Color.purple.gradient : Color.orange.gradient)
                                    
                                    RuleMark(y: .value("Target", 7.0))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                        .foregroundStyle(.purple.opacity(0.5))
                                }
                            }
                        }
                        .frame(height: 220)
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
                        
                        // Chart Legend
                        HStack(spacing: 16) {
                            Image(systemName: selectedMetric.icon)
                                .foregroundColor(selectedMetric.color)
                            
                            Text(metricDescription())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Daily Breakdown Table
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Breakdown")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                            GridRow {
                                Text("Day")
                                    .font(.caption.bold())
                                    .foregroundColor(.pgAccent)
                                Text("Steps")
                                    .font(.caption.bold())
                                    .foregroundColor(.pgAccent)
                                Text("Sleep")
                                    .font(.caption.bold())
                                    .foregroundColor(.pgAccent)
                                Text("Stress")
                                    .font(.caption.bold())
                                    .foregroundColor(.pgAccent)
                            }
                            
                            Divider()
                                .gridCellColumns(4)
                            
                            ForEach(weeklyData) { day in
                                GridRow {
                                    HStack(spacing: 4) {
                                        Text(day.day)
                                            .font(.caption)
                                        if day.stepsGoalMet && day.goodSleep && day.lowStress {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("\(day.steps / 1000)K")
                                            .font(.caption)
                                        if day.stepsGoalMet {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    Text(String(format: "%.1fh", day.sleepHours))
                                        .font(.caption)
                                        .foregroundColor(day.goodSleep ? .green : .orange)
                                    
                                    Text(String(format: "%.0f", day.stressScore))
                                        .font(.caption)
                                        .foregroundColor(day.lowStress ? .green : .orange)
                                }
                                .foregroundColor(.lightText)
                            }
                        }
                        
                        // Legend
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                Text("Perfect Day")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("Goal Met")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Insights and Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Weekly Insights")
                                .font(.headline)
                                .foregroundColor(.lightText)
                        }
                        
                        WeeklyInsight(
                            icon: "chart.line.uptrend.xyaxis",
                            text: generateStepsInsight(),
                            color: .pgAccent
                        )
                        
                        WeeklyInsight(
                            icon: "bed.double.fill",
                            text: generateSleepInsight(),
                            color: .purple
                        )
                        
                        WeeklyInsight(
                            icon: "waveform.path.ecg",
                            text: generateStressInsight(),
                            color: .orange
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Quick Navigation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Explore More")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        NavigationCard(
                            title: "Stress Forecast",
                            subtitle: "View 7-day stress predictions",
                            icon: "waveform.path.ecg",
                            color: .orange,
                            destination: StressForecastView()
                        )
                        
                        NavigationCard(
                            title: "Emotion Insights",
                            subtitle: "Understand your emotional state",
                            icon: "face.smiling.fill",
                            color: .blue,
                            destination: EmotionInsightsView()
                        )
                        
                        NavigationCard(
                            title: "Adaptive Goals",
                            subtitle: "Track personalized targets",
                            icon: "flag.fill",
                            color: .green,
                            destination: AdaptiveGoalsView()
                        )
                        
                        NavigationCard(
                            title: "Recovery Plan",
                            subtitle: "Optimize your rest schedule",
                            icon: "alarm.fill",
                            color: .pgAccent,
                            destination: RecoveryAlarmsView()
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
            .sheet(isPresented: $showExportSheet) {
                ExportOptionsSheet()
            }
        }
    }
    
    private func dateRangeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: today))"
    }
    
    private func metricDescription() -> String {
        switch selectedMetric {
        case .steps:
            return "Daily step count. Goal: 8,000 steps per day"
        case .stress:
            return "Stress score (0-100). Lower is better. Target: <50"
        case .sleep:
            return "Hours of sleep per night. Target: 7+ hours"
        }
    }
    
    private func generateStepsInsight() -> String {
        let avg = weeklyAverages.steps
        if avg >= 10000 {
            return "Excellent activity! You averaged \(avg) steps this week."
        } else if avg >= 8000 {
            return "Good job! You're meeting your daily step goals consistently."
        } else {
            return "Try to increase daily activity. Aim for 8,000+ steps per day."
        }
    }
    
    private func generateSleepInsight() -> String {
        let avg = weeklyAverages.sleep
        if avg >= 8.0 {
            return "Excellent sleep! You're getting optimal rest at \(String(format: "%.1f", avg)) hours/night."
        } else if avg >= 7.0 {
            return "Good sleep quality at \(String(format: "%.1f", avg)) hours/night. Keep it up!"
        } else {
            return "Sleep needs improvement. Target 7-8 hours per night for better recovery."
        }
    }
    
    private func generateStressInsight() -> String {
        let avg = weeklyAverages.stress
        if avg < 30 {
            return "Low stress levels this week (\(String(format: "%.0f", avg))/100). Great work managing stress!"
        } else if avg < 60 {
            return "Moderate stress levels (\(String(format: "%.0f", avg))/100). Balance activity with rest."
        } else {
            return "High stress detected (\(String(format: "%.0f", avg))/100). Prioritize recovery activities."
        }
    }
}

// MARK: - Supporting Views

struct WeeklyScoreCard: View {
    let averages: (steps: Int, stress: Double, sleep: Double)
    
    var overallScore: Int {
        let stepScore = min(100, (Double(averages.steps) / 10000.0) * 100)
        let stressScore = max(0, 100 - averages.stress)
        let sleepScore = min(100, (averages.sleep / 8.0) * 100)
        return Int((stepScore + stressScore + sleepScore) / 3)
    }
    
    var scoreColor: Color {
        switch overallScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(overallScore)")
                            .font(.system(size: 56, weight: .black))
                            .foregroundColor(scoreColor)
                        Text("/100")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: Double(overallScore) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: overallScore)
                }
                .frame(width: 70, height: 70)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack(spacing: 20) {
                AverageBadge(icon: "figure.walk", value: "\(averages.steps)", label: "Steps", color: .pgAccent)
                AverageBadge(icon: "bed.double.fill", value: String(format: "%.1f", averages.sleep), label: "Sleep", color: .purple)
                AverageBadge(icon: "waveform.path.ecg", value: String(format: "%.0f", averages.stress), label: "Stress", color: .orange)
            }
        }
        .padding(24)
        .elevatedCardStyle()
    }
}

struct AverageBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.lightText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementRow: View {
    let achievement: WeeklyReportView.Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: achievement.icon)
                    .foregroundColor(achievement.color)
                
                Text(achievement.title)
                    .font(.subheadline)
                    .foregroundColor(.lightText)
                
                Spacer()
                
                Text("\(achievement.count)/\(achievement.total)")
                    .font(.subheadline.bold())
                    .foregroundColor(achievement.color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(achievement.color)
                        .frame(width: geometry.size.width * achievement.percentage)
                        .animation(.spring(), value: achievement.percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

struct WeeklyInsight: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct NavigationCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.lightText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground.opacity(0.5))
            )
        }
    }
}

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Export Format") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("PDF Report")
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "tablecells")
                            Text("CSV Data")
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Image Summary")
                        }
                    }
                }
                
                Section("Share") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Report")
                        }
                    }
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WeeklyReportView()
        .environmentObject(AppViewModel.shared)
}
