//
//  StressContributorsView.swift
//  CP317-Application
//

import SwiftUI
import Charts

struct StressContributorsView: View {
    let sleepImpact: Double
    let heartRateImpact: Double
    let activityImpact: Double
    let moodImpact: Double
    let hrvImpact: Double
    
    struct ContributorData: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let icon: String
        let color: Color
    }
    
    var contributorsList: [ContributorData] {
        [
            ContributorData(name: "Sleep", value: sleepImpact, icon: "bed.double.fill", color: .purple),
            ContributorData(name: "Heart Rate", value: heartRateImpact, icon: "heart.fill", color: .red),
            ContributorData(name: "HRV", value: hrvImpact, icon: "waveform", color: .blue),
            ContributorData(name: "Mood", value: moodImpact, icon: "face.smiling", color: .yellow),
            ContributorData(name: "Activity", value: activityImpact, icon: "figure.walk", color: .green)
        ].sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Contributors")
                .font(.headline)
                .foregroundColor(.lightText)
            
            contributorsChart
            
            contributorDetailsList
            
            if let topContributor = contributorsList.first, topContributor.value > 0.6 {
                recommendationBanner(for: topContributor.name)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - Chart View
    private var contributorsChart: some View {
        Chart(contributorsList) { contributor in
            BarMark(
                x: .value("Impact", contributor.value * 100),
                y: .value("Factor", contributor.name)
            )
            .foregroundStyle(contributor.color.gradient)
            .cornerRadius(6)
            .annotation(position: .trailing) {
                annotationText(for: contributor)
            }
        }
        .frame(height: 200)
        .chartXScale(domain: 0...100)
        .chartXAxis {
            xAxisMarks
        }
        .chartYAxis {
            yAxisMarks
        }
    }
    
    // MARK: - Chart Components
    private func annotationText(for contributor: ContributorData) -> some View {
        Text(String(format: "%.0f%%", contributor.value * 100))
            .font(.caption.bold())
            .foregroundColor(contributor.color)
    }
    
    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks { _ in
            AxisGridLine()
                .foregroundStyle(Color.white.opacity(0.1))
            AxisValueLabel()
                .foregroundStyle(.secondary)
        }
    }
    
    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks { value in
            AxisValueLabel {
                yAxisLabel(for: value)
            }
            .foregroundStyle(Color.lightText)
        }
    }
    
    @ViewBuilder
    private func yAxisLabel(for value: AxisValue) -> some View {
        if let name = value.as(String.self),
           let contributor = contributorsList.first(where: { $0.name == name }) {
            HStack(spacing: 6) {
                Image(systemName: contributor.icon)
                    .foregroundColor(contributor.color)
                    .font(.caption)
                Text(name)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Detail List
    private var contributorDetailsList: some View {
        VStack(spacing: 8) {
            ForEach(contributorsList) { contributor in
                ContributorDetailRow(contributor: contributor)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Recommendation Banner
    private func recommendationBanner(for factor: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text(getRecommendation(for: factor))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    func getRecommendation(for factor: String) -> String {
        switch factor {
        case "Sleep":
            return "Sleep is your primary stress factor. Aim for 7-8 hours tonight and maintain a consistent bedtime."
        case "Heart Rate":
            return "Elevated heart rate detected. Try deep breathing exercises or light activity to help regulate."
        case "HRV":
            return "Low heart rate variability. Focus on stress reduction techniques like meditation or gentle yoga."
        case "Mood":
            return "Your mood check indicates stress. Consider talking to someone or engaging in activities you enjoy."
        case "Activity":
            return "Activity imbalance detected. Aim for moderate, consistent daily movement rather than extremes."
        default:
            return "Focus on balanced rest, nutrition, and stress management."
        }
    }
}

// MARK: - Supporting Views

struct ContributorDetailRow: View {
    let contributor: StressContributorsView.ContributorData
    
    var impactLevel: String {
        switch contributor.value {
        case 0..<0.3: return "Low Impact"
        case 0.3..<0.6: return "Moderate Impact"
        case 0.6..<0.8: return "High Impact"
        default: return "Critical Impact"
        }
    }
    
    var impactColor: Color {
        switch contributor.value {
        case 0..<0.3: return .green
        case 0.3..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            contributorIcon
            contributorInfo
            Spacer()
            contributorMetrics
        }
        .padding(.vertical, 4)
    }
    
    private var contributorIcon: some View {
        ZStack {
            Circle()
                .fill(contributor.color.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: contributor.icon)
                .foregroundColor(contributor.color)
                .font(.subheadline)
        }
    }
    
    private var contributorInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(contributor.name)
                .font(.subheadline.bold())
                .foregroundColor(.lightText)
            
            Text(impactLevel)
                .font(.caption)
                .foregroundColor(impactColor)
        }
    }
    
    private var contributorMetrics: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(format: "%.0f%%", contributor.value * 100))
                .font(.subheadline.bold())
                .foregroundColor(.lightText)
            
            ProgressView(value: contributor.value)
                .tint(impactColor)
                .frame(width: 60)
        }
    }
}

#Preview {
    StressContributorsView(
        sleepImpact: 0.7,
        heartRateImpact: 0.4,
        activityImpact: 0.3,
        moodImpact: 0.6,
        hrvImpact: 0.5
    )
    .padding()
    .background(Color.darkBackground)
}
