import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [
                    Color(hex: "#0f172a"),
                    Color(hex: "#1e293b")
                ]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab Selector
                    tabSelectorView
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        dashboardView.tag(0)
                        metricsView.tag(1)
                        activityView.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Dashboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Last updated: \(healthManager.latestData.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: { healthManager.refreshAllData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            if let error = healthManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(error)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal)
            }
        }
        .padding(.top, 50)
        .padding(.bottom)
    }
    
    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            TabButton(title: "Overview", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Metrics", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Activity", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Quick Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatCard(
                        title: "Steps",
                        value: "\(healthManager.latestData.stepCount)",
                        subtitle: "Today",
                        icon: "figure.walk",
                        color: .blue,
                        isLoading: healthManager.isLoading
                    )
                    
                    StatCard(
                        title: "Heart Rate",
                        value: "\(healthManager.latestData.heartRate)",
                        subtitle: "BPM",
                        icon: "heart.fill",
                        color: .red,
                        isLoading: healthManager.isLoading
                    )
                    
                    StatCard(
                        title: "Active Energy",
                        value: String(format: "%.0f", healthManager.latestData.activeEnergy),
                        subtitle: "Calories",
                        icon: "flame.fill",
                        color: .orange,
                        isLoading: healthManager.isLoading
                    )
                    
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.1f", healthManager.latestData.walkingDistance),
                        subtitle: "Kilometers",
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        color: .green,
                        isLoading: healthManager.isLoading
                    )
                }
                
                // Sleep Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.purple)
                        Text("Sleep Analysis")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1fh", healthManager.latestData.sleepHours))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    
                    ProgressView(value: min(healthManager.latestData.sleepHours / 8.0, 1.0))
                        .tint(.purple)
                    
                    Text("\(String(format: "%.1f", healthManager.latestData.sleepHours)) hours of 8 recommended")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .redacted(reason: healthManager.isLoading ? .placeholder : [])
                
                // Weekly Summary Placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        WeekDayView(day: "M", progress: 0.7)
                        WeekDayView(day: "T", progress: 0.9)
                        WeekDayView(day: "W", progress: 0.6)
                        WeekDayView(day: "T", progress: 0.8)
                        WeekDayView(day: "F", progress: 0.5)
                        WeekDayView(day: "S", progress: 0.3)
                        WeekDayView(day: "S", progress: 0.4)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
        }
        .refreshable {
            healthManager.refreshAllData()
        }
    }
    
    private var metricsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricDetailCard(
                    title: "Heart Rate Analytics",
                    currentValue: healthManager.latestData.heartRate,
                    unit: "BPM",
                    trend: "+2 from yesterday",
                    icon: "heart.fill",
                    color: .red
                )
                
                MetricDetailCard(
                    title: "Step Analysis",
                    currentValue: healthManager.latestData.stepCount,
                    unit: "Steps",
                    trend: "Goal: 10,000",
                    icon: "figure.walk",
                    color: .blue
                )
                
                MetricDetailCard(
                    title: "Energy Expenditure",
                    currentValue: Int(healthManager.latestData.activeEnergy),
                    unit: "Cal",
                    trend: "Active today",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding()
        }
    }
    
    private var activityView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Activity Rings")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                // Activity Rings Placeholder
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(150))
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(30))
                    
                    VStack {
                        Text("720")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                .padding()
                
                Text("Recent Activities")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                ForEach(0..<3) { _ in
                    ActivityRow()
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(height: 120)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .redacted(reason: isLoading ? .placeholder : [])
    }
}

struct WeekDayView: View {
    let day: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 8, height: 40)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 8, height: CGFloat(progress * 40))
                    .cornerRadius(4)
            }
            
            Text(day)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct MetricDetailCard: View {
    let title: String
    let currentValue: Int
    let unit: String
    let trend: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(currentValue)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.body)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Walk")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("45 min • 3.2 km")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("8:00 AM")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Health Data") {
                    Button("Refresh All Data") {
                        HealthManager.shared.refreshAllData()
                        dismiss()
                    }
                    
                    Button("Request Permissions") {
                        HealthManager.shared.requestAuthorization { _, _ in
                            dismiss()
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Keep the existing Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
