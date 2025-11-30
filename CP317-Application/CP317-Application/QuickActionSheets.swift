//
//  QuickActionSheets.swift.swift
//  CP317-Application
//
//  Created by Himanya Verma on 2025-11-27.
//

//
//  QuickActionSheets.swift
//  CP317-Application
//

import SwiftUI

// MARK: - Activity Log Sheet

struct ActivityLogSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var activityType = "Walking"
    @State private var duration = 30.0
    @State private var intensity = "Moderate"
    @State private var notes = ""
    @State private var showingSuccess = false
    
    let activityTypes = ["Walking", "Running", "Cycling", "Swimming", "Gym", "Yoga", "Other"]
    let intensityLevels = ["Light", "Moderate", "Vigorous"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    Picker("Activity Type", selection: $activityType) {
                        ForEach(activityTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(Int(duration)) minutes")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $duration, in: 5...180, step: 5)
                            .tint(.pgAccent)
                    }
                    
                    Picker("Intensity", selection: $intensity) {
                        ForEach(intensityLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: logActivity) {
                        HStack {
                            Spacer()
                            if showingSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Logged!")
                                }
                                .foregroundColor(.green)
                            } else {
                                Text("Log Activity")
                                    .foregroundColor(.pgAccent)
                            }
                            Spacer()
                        }
                    }
                    .disabled(showingSuccess)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func logActivity() {
        withAnimation {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Water Log Sheet

struct WaterLogSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var waterAmount = 250.0
    @State private var todayTotal = 0
    @State private var showingSuccess = false
    
    let dailyGoal = 2000 // ml (about 8 glasses)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Water visualization
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(todayTotal) / Double(dailyGoal), 1.0))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: todayTotal)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("\(todayTotal) ml")
                            .font(.title.bold())
                            .foregroundColor(.lightText)
                        
                        Text("of \(dailyGoal) ml")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Add Water Intake")
                        .font(.headline)
                        .foregroundColor(.lightText)
                    
                    HStack(spacing: 16) {
                        QuickWaterButton(amount: 250, todayTotal: $todayTotal, icon: "cup.and.saucer.fill")
                        QuickWaterButton(amount: 500, todayTotal: $todayTotal, icon: "waterbottle.fill")
                        QuickWaterButton(amount: 750, todayTotal: $todayTotal, icon: "takeoutbag.and.cup.and.straw.fill")
                    }
                    
                    // Custom amount slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Custom Amount")
                                .font(.subheadline)
                                .foregroundColor(.lightText)
                            Spacer()
                            Text("\(Int(waterAmount)) ml")
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $waterAmount, in: 50...1000, step: 50)
                            .tint(.blue)
                        
                        Button(action: {
                            withAnimation {
                                todayTotal += Int(waterAmount)
                                showingSuccess = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showingSuccess = false
                            }
                        }) {
                            HStack {
                                if showingSuccess {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Added!")
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add \(Int(waterAmount)) ml")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showingSuccess ? Color.green : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(showingSuccess)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                }
                .padding()
                
                Spacer()
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("Water Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct QuickWaterButton: View {
    let amount: Int
    @Binding var todayTotal: Int
    let icon: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                todayTotal += amount
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text("\(amount) ml")
                    .font(.caption.bold())
                    .foregroundColor(.lightText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPressed ? Color.blue.opacity(0.3) : Color.cardBackground)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// MARK: - Sleep Log Sheet

struct SleepLogSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var bedTime = Date()
    @State private var wakeTime = Date()
    @State private var sleepQuality = 3.0
    @State private var notes = ""
    @State private var showingSuccess = false
    
    var sleepDuration: String {
        let interval = wakeTime.timeIntervalSince(bedTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours < 0 {
            return "Invalid times"
        }
        return "\(hours)h \(minutes)m"
    }
    
    var qualityLabel: String {
        switch sleepQuality {
        case 0..<1.5: return "Poor"
        case 1.5..<2.5: return "Fair"
        case 2.5..<3.5: return "Good"
        case 3.5..<4.5: return "Very Good"
        default: return "Excellent"
        }
    }
    
    var qualityColor: Color {
        switch sleepQuality {
        case 0..<1.5: return .red
        case 1.5..<2.5: return .orange
        case 2.5..<3.5: return .yellow
        case 3.5..<4.5: return .green
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sleep Times") {
                    DatePicker("Bed Time", selection: $bedTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(sleepDuration)
                            .font(.headline)
                            .foregroundColor(.pgAccent)
                    }
                }
                
                Section("Sleep Quality") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(qualityLabel)
                                .font(.headline)
                                .foregroundColor(qualityColor)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(sleepQuality) + 1 ? "star.fill" : "star")
                                        .foregroundColor(qualityColor)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Slider(value: $sleepQuality, in: 0...4, step: 1)
                            .tint(qualityColor)
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: logSleep) {
                        HStack {
                            Spacer()
                            if showingSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Sleep Logged!")
                                }
                                .foregroundColor(.green)
                            } else {
                                Text("Log Sleep")
                                    .foregroundColor(.purple)
                            }
                            Spacer()
                        }
                    }
                    .disabled(showingSuccess)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func logSleep() {
        withAnimation {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Mood Check Sheet

struct MoodCheckSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedMood: Mood = .neutral
    @State private var energyLevel = 3.0
    @State private var stressLevel = 3.0
    @State private var notes = ""
    @State private var showingSuccess = false
    
    enum Mood: String, CaseIterable {
        case veryHappy = "😄"
        case happy = "🙂"
        case neutral = "😐"
        case sad = "😔"
        case verySad = "😢"
        
        var label: String {
            switch self {
            case .veryHappy: return "Very Happy"
            case .happy: return "Happy"
            case .neutral: return "Neutral"
            case .sad: return "Sad"
            case .verySad: return "Very Sad"
            }
        }
        
        var color: Color {
            switch self {
            case .veryHappy: return .green
            case .happy: return .blue
            case .neutral: return .yellow
            case .sad: return .orange
            case .verySad: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        HStack(spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedMood = mood
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(mood.rawValue)
                                            .font(.system(size: 40))
                                        
                                        Text(mood.label)
                                            .font(.caption2)
                                            .foregroundColor(.lightText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedMood == mood ? mood.color.opacity(0.3) : Color.cardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    
                    // Energy Level
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text("Energy Level")
                                .font(.headline)
                                .foregroundColor(.lightText)
                            
                            Spacer()
                            
                            Text("\(Int(energyLevel))/5")
                                .font(.subheadline.bold())
                                .foregroundColor(.yellow)
                        }
                        
                        Slider(value: $energyLevel, in: 1...5, step: 1)
                            .tint(.yellow)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    
                    // Stress Level
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.orange)
                            Text("Stress Level")
                                .font(.headline)
                                .foregroundColor(.lightText)
                            
                            Spacer()
                            
                            Text("\(Int(stressLevel))/5")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        }
                        
                        Slider(value: $stressLevel, in: 1...5, step: 1)
                            .tint(.orange)
                        
                        HStack {
                            Text("Relaxed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Stressed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's on your mind? (Optional)")
                            .font(.headline)
                            .foregroundColor(.lightText)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    
                    // Submit Button
                    Button(action: logMood) {
                        HStack {
                            if showingSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mood Logged!")
                            } else {
                                Image(systemName: "heart.fill")
                                Text("Save Mood Check")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showingSuccess ? Color.green : selectedMood.color)
                        .cornerRadius(12)
                    }
                    .disabled(showingSuccess)
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("Mood Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.pink)
                }
            }
        }
    }
    
    private func logMood() {
        withAnimation {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ActivityLogSheet()
}
