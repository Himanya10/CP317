//
//  StressForecastView.swift
//  CP317-Application
//

import SwiftUI
import Charts

@MainActor
struct StressForecastView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var aiModel: PredictionEngine
    @StateObject private var moodManager = MoodDataManager.shared
    @State private var selectedDay: String?
    @State private var showingDetails = false
    
    struct DailyForecast: Identifiable {
        let id = UUID()
        let day: String
        let dayShort: String
        let score: Double
        let burnoutRisk: Double
    }
    
    var weeklyData: [DailyForecast] {
        let currentScore = aiModel.cachedStress?.predictedStressScore ?? 35.0
        let burnout = aiModel.cachedStress?.burnoutRisk ?? 0.1
        
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let shorts = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let pattern: [Double] = [0.85, 0.95, 1.1, 1.15, 1.0, 0.7, 0.6]
        
        var results: [DailyForecast] = []
        for i in 0..<7 {
            let dayScore = currentScore * pattern[i]
            let clampedScore = min(100, dayScore)
            
            let dayBurnout = burnout * pattern[i]
            let clampedBurnout = min(1.0, dayBurnout)
            
            let forecast = DailyForecast(
                day: days[i],
                dayShort: shorts[i],
                score: clampedScore,
                burnoutRisk: clampedBurnout
            )
            results.append(forecast)
        }
        return results
    }
    
    var currentScore: Int {
        let score = aiModel.cachedStress?.predictedStressScore ?? 35.0
        return Int(score)
    }
    
    var optimalRestTime: String {
        return aiModel.cachedStress?.optimalRestTime ?? "9:30 PM"
    }
    
    var burnoutRisk: Double {
        return aiModel.cachedStress?.burnoutRisk ?? 0.05
    }
    
    var stressLevel: (text: String, color: Color, icon: String) {
        let score = currentScore
        
        if score < 30 {
            return ("Low", .green, "face.smiling.fill")
        } else if score < 60 {
            return ("Moderate", .yellow, "face.neutral.fill")
        } else if score < 80 {
            return ("High", .orange, "exclamationmark.triangle.fill")
        } else {
            return ("Critical", .red, "exclamationmark.octagon.fill")
        }
    }
    
    var selectedDayData: DailyForecast? {
        guard let day = selectedDay else { return nil }
        
        for data in weeklyData {
            if data.dayShort == day {
                return data
            }
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                currentStressCard
                weeklyChartSection
                contributingFactorsSection
                stressContributorsSection
                liveDataSourcesSection
                recommendationsSection
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .background(Color.darkBackground.ignoresSafeArea())
        .sheet(isPresented: $showingDetails) {
            StressInfoSheet()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        HStack {
            Text("Stress Forecast")
                .font(.largeTitle.bold())
                .foregroundColor(.lightText)
            
            Spacer()
            
            Button(action: { showingDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.pgAccent)
            }
        }
        .padding(.horizontal)
    }
    
    private var currentStressCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                stressScoreDisplay
                Spacer()
                circularProgressIndicator
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            metricsRow
        }
        .padding(24)
        .elevatedCardStyle()
        .padding(.horizontal)
    }
    
    private var stressScoreDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Level")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currentScore)")
                    .font(.system(size: 72, weight: .black))
                    .foregroundColor(stressLevel.color)
                Text("/100")
                    .font(.title2.bold())
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: stressLevel.icon)
                    .foregroundColor(stressLevel.color)
                Text(stressLevel.text)
                    .font(.headline)
                    .foregroundColor(stressLevel.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(stressLevel.color.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    private var circularProgressIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: Double(currentScore) / 100.0)
                .stroke(stressLevel.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: currentScore)
            
            Image(systemName: stressLevel.icon)
                .font(.title)
                .foregroundColor(stressLevel.color)
        }
        .frame(width: 90, height: 90)
    }
    
    private var metricsRow: some View {
        HStack(spacing: 16) {
            MetricBadge(
                icon: "flame.fill",
                title: "Burnout Risk",
                value: String(format: "%.0f%%", burnoutRisk * 100),
                color: burnoutRisk > 0.6 ? .red : (burnoutRisk > 0.3 ? .orange : .green)
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
            
            MetricBadge(
                icon: "moon.stars.fill",
                title: "Rest Time",
                value: optimalRestTime,
                color: .pgAccent
            )
        }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            weeklyChartHeader
            weeklyChart
            weeklyChartTip
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
    
    private var weeklyChartHeader: some View {
        HStack {
            Text("7-Day Trend")
                .font(.headline)
                .foregroundColor(.lightText)
            
            Spacer()
            
            if let selected = selectedDayData {
                Text("\(selected.day): \(Int(selected.score))")
                    .font(.caption)
                    .foregroundColor(.pgAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pgAccent.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
    
    private var weeklyChart: some View {
        Chart(weeklyData) { data in
            AreaMark(
                x: .value("Day", data.dayShort),
                y: .value("Score", data.score)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.pgPrimary.opacity(0.4), Color.pgPrimary.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            LineMark(
                x: .value("Day", data.dayShort),
                y: .value("Score", data.score)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.pgPrimary)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            PointMark(
                x: .value("Day", data.dayShort),
                y: .value("Score", data.score)
            )
            .foregroundStyle(Color.pgPrimary)
            .symbolSize(selectedDay == data.dayShort ? 150 : 100)
            
            RuleMark(y: .value("High", 60))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .foregroundStyle(.red.opacity(0.5))
        }
        .frame(height: 240)
        .chartYScale(domain: 0...100)
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
        .chartAngleSelection(value: $selectedDay)
    }
    
    private var weeklyChartTip: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text("Stress typically peaks mid-week. Plan recovery activities for Thursday evening.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    private var contributingFactorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Factors")
                .font(.headline)
                .foregroundColor(.lightText)
            
            FactorCard(
                icon: "bed.double.fill",
                title: "Sleep Quality",
                value: vm.sleepHoursToday,
                target: 8.0,
                unit: "hrs",
                color: .purple
            )
            
            FactorCard(
                icon: "heart.fill",
                title: "Heart Rate",
                value: Double(vm.currentHeartRate),
                target: 75.0,
                unit: "bpm",
                color: .red,
                isInverted: true
            )
            
            FactorCard(
                icon: "figure.walk",
                title: "Activity Level",
                value: Double(vm.stepsToday),
                target: Double(vm.stepsGoal),
                unit: "steps",
                color: .pgAccent
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var stressContributorsSection: some View {
        if let contributors = aiModel.cachedStress?.contributors {
            StressContributorsView(
                sleepImpact: contributors.sleepImpact,
                heartRateImpact: contributors.heartRateImpact,
                activityImpact: contributors.activityImpact,
                moodImpact: contributors.moodImpact,
                hrvImpact: contributors.hrvImpact
            )
            .padding(.horizontal)
        }
    }
    
    private var liveDataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            liveDataHeader
            dataSourcesList
            liveDataTip
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
    
    private var liveDataHeader: some View {
        HStack {
            Image(systemName: "waveform.path.ecg.fill")
                .foregroundColor(.pgAccent)
            Text("Live Data Sources")
                .font(.headline)
                .foregroundColor(.lightText)
            
            Spacer()
            
            if let confidence = aiModel.cachedStress?.confidence {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(String(format: "%.0f%% confident", confidence * 100))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var dataSourcesList: some View {
        VStack(spacing: 10) {
            DataSourceRow(
                icon: "heart.fill",
                label: "Heart Rate",
                value: vm.currentHeartRate > 0 ? "\(vm.currentHeartRate) BPM" : "No data",
                isActive: vm.currentHeartRate > 0,
                color: .red
            )
            
            DataSourceRow(
                icon: "bed.double.fill",
                label: "Sleep",
                value: vm.sleepHoursToday > 0 ? String(format: "%.1f hrs", vm.sleepHoursToday) : "No data",
                isActive: vm.sleepHoursToday > 0,
                color: .purple
            )
            
            DataSourceRow(
                icon: "figure.walk",
                label: "Activity",
                value: "\(vm.stepsToday) steps",
                isActive: vm.stepsToday > 0,
                color: .pgAccent
            )
            
            DataSourceRow(
                icon: "face.smiling",
                label: "Mood Check",
                value: moodManager.latestMood != nil ? "Latest: \(timeAgoString(moodManager.latestMood!.timestamp))" : "No data",
                isActive: moodManager.latestMood != nil,
                color: .yellow
            )
        }
    }
    
    private var liveDataTip: some View {
        Text("💡 Your stress score updates automatically as new health data becomes available")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.pgSecondary)
                Text("AI Recommendations")
                    .font(.headline)
                    .foregroundColor(.lightText)
            }
            
            recommendationsList
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var recommendationsList: some View {
        if currentScore > 60 {
            StressRecommendationRow(
                icon: "wind",
                text: "High stress detected. Try 10 minutes of deep breathing",
                priority: .high
            )
            StressRecommendationRow(
                icon: "figure.walk",
                text: "Take a 15-minute walk in nature",
                priority: .medium
            )
            StressRecommendationRow(
                icon: "person.2",
                text: "Connect with a friend or loved one",
                priority: .medium
            )
        } else if currentScore > 30 {
            StressRecommendationRow(
                icon: "calendar",
                text: "Schedule short breaks throughout the day",
                priority: .medium
            )
            StressRecommendationRow(
                icon: "bed.double",
                text: "Maintain consistent sleep schedule",
                priority: .low
            )
        } else {
            StressRecommendationRow(
                icon: "checkmark.circle.fill",
                text: "Great stress management! Keep up your routine",
                priority: .low
            )
            StressRecommendationRow(
                icon: "chart.line.uptrend.xyaxis",
                text: "Continue monitoring your wellness patterns",
                priority: .low
            )
        }
    }
    
    func timeAgoString(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Supporting Components

struct DataSourceRow: View {
    let icon: String
    let label: String
    let value: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(isActive ? color : .secondary)
                    .font(.subheadline)
            }
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.lightText)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.caption)
                    .foregroundColor(isActive ? .lightText : .secondary)
                
                Circle()
                    .fill(isActive ? .green : .secondary)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MetricBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.lightText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FactorCard: View {
    let icon: String
    let title: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    var isInverted: Bool = false
    
    var percentage: Double {
        guard target > 0 else { return 0 }
        let ratio = value / target
        return isInverted ? (2.0 - ratio) : ratio
    }
    
    var status: (text: String, color: Color) {
        switch percentage {
        case 0.8...: return ("Excellent", .green)
        case 0.6..<0.8: return ("Good", .yellow)
        case 0.4..<0.6: return ("Fair", .orange)
        default: return ("Needs Attention", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.lightText)
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.0f %@", value, unit))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("of \(Int(target))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(status.text)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.2))
                    .foregroundColor(status.color)
                    .cornerRadius(8)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(status.color)
                        .frame(width: geometry.size.width * min(percentage, 1.0))
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground.opacity(0.5))
        )
    }
}

struct StressRecommendationRow: View {
    let icon: String
    let text: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
        
        var badge: String {
            switch self {
            case .high: return "High Priority"
            case .medium: return "Medium"
            case .low: return "Low Priority"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.pgAccent)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.lightText)
                
                if priority != .low {
                    Text(priority.badge)
                        .font(.caption2)
                        .foregroundColor(priority.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priority.color.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct StressInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding Your Stress Score")
                        .font(.title2.bold())
                        .foregroundColor(.lightText)
                    
                    InfoSection(
                        title: "What We Measure",
                        content: "Your stress score is calculated using heart rate variability, sleep quality, activity levels, mood check responses, and recovery patterns."
                    )
                    
                    InfoSection(
                        title: "Stress Levels",
                        content: "• 0-30: Low stress - maintain current habits\n• 30-60: Moderate - balance activity and rest\n• 60-80: High - prioritize recovery\n• 80+: Critical - immediate rest needed"
                    )
                    
                    InfoSection(
                        title: "Burnout Risk",
                        content: "Indicates likelihood of exhaustion if current patterns continue. Take action when risk exceeds 50%."
                    )
                    
                    InfoSection(
                        title: "Mood Impact",
                        content: "Your mood check responses are weighted at 20% in stress calculations. Regular mood logging improves accuracy."
                    )
                }
                .padding()
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.pgAccent)
                }
            }
        }
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.pgAccent)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    StressForecastView()
        .environmentObject(AppViewModel.preview)
        .environmentObject(PredictionEngine.shared)
}
