//
//  EmotionInsightsView.swift
//  CP317-Application
//
//  Created by Himanya Verma on 2025-11-25.
//

import SwiftUI

@MainActor
struct EmotionInsightsView: View {
    @ObservedObject var aiModel = PredictionEngine.shared
    
    var detectedEmotion: String {
        aiModel.cachedEmotion?.dominantEmotion ?? "Neutral"
    }
    
    var explanation: String {
        aiModel.cachedEmotion?.explanation ?? "No recent emotional data available."
    }
    
    var tensionLevel: Double {
        aiModel.cachedEmotion?.tensionLevel ?? 0.0
    }
    
    var energyLevel: Double {
        aiModel.cachedEmotion?.energyLevel ?? 0.0
    }
    
    var emotionColor: Color {
        switch detectedEmotion.lowercased() {
        case "tension": return .orange
        case "vigorous": return .green
        case "fatigued": return .purple
        case "calm": return .blue
        default: return .pgAccent
        }
    }
    
    var emotionIcon: String {
        switch detectedEmotion.lowercased() {
        case "tension": return "bolt.fill"
        case "vigorous": return "flame.fill"
        case "fatigued": return "moon.fill"
        case "calm": return "leaf.fill"
        default: return "face.smiling"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                Text("Emotion Insights")
                    .font(.largeTitle.bold())
                    .foregroundColor(.lightText)
                    .padding(.horizontal)
                
                // Main Emotion Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current State")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: emotionIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(emotionColor)
                                
                                Text(detectedEmotion)
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(emotionColor)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // AI Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.pgSecondary)
                            Text("Analysis")
                                .font(.headline)
                                .foregroundColor(.lightText)
                        }
                        
                        Text(explanation)
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
                
                // Metrics Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emotional Metrics")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    HStack(spacing: 16) {
                        MetricCard(
                            title: "Tension",
                            value: tensionLevel,
                            icon: "waveform.path.ecg",
                            color: tensionLevel > 0.6 ? .orange : .green
                        )
                        
                        MetricCard(
                            title: "Energy",
                            value: energyLevel,
                            icon: "bolt.fill",
                            color: energyLevel > 0.7 ? .green : (energyLevel < 0.3 ? .purple : .yellow)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Contributing Factors
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contributing Factors")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    FactorRow(
                        icon: "heart.fill",
                        label: "Tension Level",
                        value: String(format: "%.0f%%", tensionLevel * 100),
                        progress: tensionLevel,
                        color: tensionLevel > 0.6 ? .orange : .green
                    )
                    
                    FactorRow(
                        icon: "figure.run",
                        label: "Energy Level",
                        value: String(format: "%.0f%%", energyLevel * 100),
                        progress: energyLevel,
                        color: energyLevel > 0.7 ? .green : (energyLevel < 0.3 ? .purple : .yellow)
                    )
                    
                    FactorRow(
                        icon: "bed.double.fill",
                        label: "Sleep Quality Impact",
                        value: tensionLevel > 0.5 ? "High" : "Low",
                        progress: tensionLevel > 0.5 ? 0.8 : 0.3,
                        color: tensionLevel > 0.5 ? .orange : .green
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
                
                // Wellness Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.pgAccent)
                        Text("Wellness Tips")
                            .font(.headline)
                            .foregroundColor(.lightText)
                    }
                    
                    if tensionLevel > 0.6 {
                        RecommendationRow(
                            icon: "wind",
                            text: "Try deep breathing exercises to reduce tension"
                        )
                        RecommendationRow(
                            icon: "figure.walk",
                            text: "Take a 10-minute walk to clear your mind"
                        )
                    } else if energyLevel < 0.3 {
                        RecommendationRow(
                            icon: "bed.double.fill",
                            text: "Consider prioritizing rest and recovery today"
                        )
                        RecommendationRow(
                            icon: "drop.fill",
                            text: "Stay hydrated to maintain energy levels"
                        )
                    } else {
                        RecommendationRow(
                            icon: "checkmark.circle.fill",
                            text: "Great emotional balance! Keep up your routine"
                        )
                        RecommendationRow(
                            icon: "heart.fill",
                            text: "Continue monitoring your wellness patterns"
                        )
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

// MARK: - Supporting Components

struct MetricCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(String(format: "%.0f%%", value * 100))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.lightText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: value)
                .tint(color)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground.opacity(0.6))
        )
    }
}

struct FactorRow: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.lightText)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.pgAccent)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EmotionInsightsView()
        .environmentObject(PredictionEngine.shared)
}
