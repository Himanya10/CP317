import SwiftUI

struct ContentView: View {
    // 1. Connect to the Health Manager (ViewModel)
    @StateObject private var healthManager = HealthManager.shared
    
    // State to manage the UI appearance after authorization
    @State private var isAuthorized = false
    @State private var authorizationAttempted = false

    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(gradient: Gradient(colors: [
                Color(hex: "#1a1a2e"), // Dark Blue/Purple
                Color(hex: "#16213e")  // Slightly Lighter Dark Blue
            ]), startPoint: .top, endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Fitness Dashboard")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()

                if !authorizationAttempted {
                    // Initial state or checking authorization
                    Text("Loading Health Status...")
                        .foregroundColor(.gray)
                } else if !isAuthorized {
                    // Authorization needed UI
                    VStack(spacing: 20) {
                        Text("Permission Required")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Please grant access to Health Data (Heart Rate & Steps) to view your metrics.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                        
                        Button(action: requestHealthAuthorization) {
                            Text("Grant Health Access")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 300)
                                .background(Color.pink.opacity(0.8))
                                .cornerRadius(12)
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                            )
                    )
                } else {
                    // Data Display
                    VStack(spacing: 20) {
                        DataCardView(
                            title: "Heart Rate",
                            value: "\(healthManager.latestData.heartRate)",
                            unit: "BPM",
                            iconName: "heart.fill",
                            color: Color(hex: "#e94560") // Pink Red
                        )
                        
                        DataCardView(
                            title: "Steps Today",
                            value: "\(healthManager.latestData.stepCount)",
                            unit: "Steps",
                            iconName: "figure.walk",
                            color: Color(hex: "#0f3460") // Dark Blue
                        )
                    }
                    .padding()
                }
                
                Spacer()
                Text("Data updated from Apple Health")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
        // Run authorization check when the view appears
        .onAppear {
            requestAuthorizationStatus()
        }
    }
    
    // MARK: - Methods
    
    func requestAuthorizationStatus() {
        // This is a simplified check for demo purposes
        healthManager.requestAuthorization { success, _ in
            self.isAuthorized = success
            self.authorizationAttempted = true
        }
    }
    
    func requestHealthAuthorization() {
        healthManager.requestAuthorization { success, error in
            if success {
                self.isAuthorized = true
            } else if let error = error {
                print("Authorization Error: \(error.localizedDescription)")
                // Optionally show a user alert here
            }
            self.authorizationAttempted = true
        }
    }
}

// MARK: - Data Card Component

struct DataCardView: View {
    let title: String
    let value: String
    let unit: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(title)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(unit)
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15)) // Glass effect
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // Subtle border
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

// MARK: - Extension for Hex Colors

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
