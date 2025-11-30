//
//  DashboardView.swift
//  CP317-Application
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var isRefreshing = false
    @State private var showingActivityLog = false
    @State private var showingWaterLog = false
    @State private var showingSleepLog = false
    @State private var showingMoodCheck = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header with refresh
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Dashboard")
                                .font(.largeTitle.bold())
                                .foregroundColor(.lightText)
                            
                            Text(currentGreeting())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { refreshData() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.pgAccent)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Hero Stats Grid - Original Metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Steps",
                            value: "\(vm.stepsToday)",
                            subtitle: "of \(vm.stepsGoal)",
                            icon: "figure.walk",
                            color: .pgAccent,
                            progress: Double(vm.stepsToday) / Double(max(vm.stepsGoal, 1)),
                            hasData: vm.stepsToday > 0
                        )
                        
                        StatCard(
                            title: "Heart Rate",
                            value: vm.currentHeartRate > 0 ? "\(vm.currentHeartRate)" : "--",
                            subtitle: "BPM",
                            icon: "heart.fill",
                            color: .red,
                            progress: nil,
                            hasData: vm.currentHeartRate > 0
                        )
                        
                        StatCard(
                            title: "Sleep",
                            value: String(format: "%.1f", vm.sleepHoursToday),
                            subtitle: "hours",
                            icon: "bed.double.fill",
                            color: .purple,
                            progress: vm.sleepHoursToday / 8.0,
                            hasData: vm.sleepHoursToday > 0
                        )
                        
                        StatCard(
                            title: "Stress",
                            value: vm.stressForecastScore > 0 ? String(format: "%.0f", vm.stressForecastScore) : "--",
                            subtitle: "/100",
                            icon: "waveform.path.ecg",
                            color: vm.isStressHigh ? .orange : .green,
                            progress: nil,
                            hasData: vm.stressForecastScore > 0
                        )
                    }
                    .padding(.horizontal)
                    
                    // New Vital Signs Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Vital Signs")
                            .font(.headline)
                            .foregroundColor(.lightText)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Blood Pressure",
                                value: vm.bloodPressure,
                                subtitle: "mmHg",
                                icon: "heart.circle",
                                color: .red,
                                progress: nil,
                                hasData: vm.hasBloodPressureData
                            )
                            
                            StatCard(
                                title: "Oxygen",
                                value: vm.oxygenSaturation,
                                subtitle: "SpO2",
                                icon: "lungs.fill",
                                color: .blue,
                                progress: nil,
                                hasData: vm.hasOxygenData
                            )
                            
                            StatCard(
                                title: "Temperature",
                                value: vm.bodyTemperature,
                                subtitle: "",
                                icon: "thermometer",
                                color: .orange,
                                progress: nil,
                                hasData: vm.hasTemperatureData
                            )
                            
                            StatCard(
                                title: "Workouts",
                                value: vm.workoutMinutes > 0 ? "\(vm.workoutMinutes)" : "0",
                                subtitle: "minutes",
                                icon: "figure.run",
                                color: .green,
                                progress: vm.workoutMinutes > 0 ? Double(vm.workoutMinutes) / 60.0 : nil,
                                hasData: vm.workoutMinutes > 0
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Activity Metrics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity & Energy")
                            .font(.headline)
                            .foregroundColor(.lightText)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Distance",
                                value: String(format: "%.2f", vm.distanceWalked),
                                subtitle: "km",
                                icon: "location.fill",
                                color: .pgAccent,
                                progress: nil,
                                hasData: vm.distanceWalked > 0
                            )
                            
                            StatCard(
                                title: "Active Calories",
                                value: "\(vm.activeCalories)",
                                subtitle: "kcal",
                                icon: "flame.fill",
                                color: .orange,
                                progress: nil,
                                hasData: vm.activeCalories > 0
                            )
                            
                            StatCard(
                                title: "Total Calories",
                                value: "\(vm.totalCalories)",
                                subtitle: "kcal",
                                icon: "chart.bar.fill",
                                color: .yellow,
                                progress: nil,
                                hasData: vm.totalCalories > 0
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // AI Insight with better visual treatment
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.pgSecondary)
                                .font(.title3)
                            Text("AI Insight")
                                .font(.headline)
                                .foregroundColor(.lightText)
                        }
                        
                        Text(vm.aiInsightText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        if vm.stressForecastScore > 0 {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundColor(.pgAccent)
                                Text("Optimal rest time: \(vm.optimalRestTimeString)")
                                    .font(.subheadline)
                                    .foregroundColor(.lightText)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.pgSecondary.opacity(0.15), Color.pgPrimary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pgSecondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.lightText)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(icon: "figure.run", title: "Log Activity", color: .pgAccent)
                                    .onTapGesture { showingActivityLog = true }
                                
                                QuickActionButton(icon: "drop.fill", title: "Water", color: .blue)
                                    .onTapGesture { showingWaterLog = true }
                                
                                QuickActionButton(icon: "moon.zzz.fill", title: "Sleep Log", color: .purple)
                                    .onTapGesture { showingSleepLog = true }
                                
                                QuickActionButton(icon: "heart.text.square.fill", title: "Mood Check", color: .pink)
                                    .onTapGesture { showingMoodCheck = true }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(Color.darkBackground.ignoresSafeArea())
            
            // Loading overlay
            if vm.isLoadingHealth || vm.isLoadingPredictions {
                LoadingOverlay(
                    isLoading: true,
                    message: vm.isLoadingHealth ? "Fetching health data..." : "Generating predictions..."
                )
            }
        }
        .sheet(isPresented: $showingActivityLog) {
            ActivityLogSheet()
        }
        .sheet(isPresented: $showingWaterLog) {
            WaterLogSheet()
        }
        .sheet(isPresented: $showingSleepLog) {
            SleepLogSheet()
        }
        .sheet(isPresented: $showingMoodCheck) {
            MoodCheckSheet()
        }
    }
    
    private func currentGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        vm.requestDataAndPredictions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRefreshing = false
        }
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double?
    let hasData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(hasData ? color : .secondary)
                    .font(.title3)
                Spacer()
            }
            
            if hasData {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.lightText)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let progress = progress {
                    ProgressView(value: min(progress, 1.0))
                        .tint(color)
                        .padding(.top, 4)
                } else {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not enough info")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(hasData ? Color.cardBackground : Color.cardBackground.opacity(0.5))
                .shadow(color: Color.black.opacity(hasData ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.lightText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.pgAccent)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.lightText)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                )
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppViewModel.preview)
}
