//
//  Theme.swift
//  CP317-Application
//

import SwiftUI

// MARK: - Color Theme

extension Color {
    /// Helper initializer for hex values
    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        return Color(.sRGB,
                     red: Double(r) / 255,
                     green: Double(g) / 255,
                     blue: Double(b) / 255,
                     opacity: Double(a) / 255)
    }
    
    // MARK: - Primary App Palette
    static let pgPrimary    = Color.fromHex("4A90E2") // Blue
    static let pgAccent     = Color.fromHex("4AD4C9") // Teal
    static let pgSecondary  = Color.fromHex("7E77FF") // Violet
    static let pgBackground = Color.fromHex("F7F9FB") // Light Grey/White

    // MARK: - Dark Theme Colors
    static let darkBackground = Color.black
    static let lightText = Color.white
    static let cardBackground = Color(white: 0.1) // Dark grey for card bodies
    
    // MARK: - Semantic Colors
    static let successGreen = Color.green
    static let warningOrange = Color.orange
    static let errorRed = Color.red
    static let infoBlue = Color.blue
    
    // MARK: - Gradient Colors
    static let gradientStart = Color.pgPrimary
    static let gradientEnd = Color.pgSecondary
    
    /// Primary gradient for accent elements
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.pgPrimary, Color.pgAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Secondary gradient for backgrounds
    static var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.pgSecondary.opacity(0.15), Color.pgPrimary.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Card gradient for elevated elements
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.cardBackground, Color.cardBackground.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Card Style Modifiers

extension View {
    /// Light theme card style
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .foregroundColor(.black)
    }
    
    /// Dark theme card style
    func darkCardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.lightText)
    }
    
    /// Premium card with gradient background
    func premiumCardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondaryGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pgSecondary.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .foregroundColor(.lightText)
    }
    
    /// Elevated card with stronger shadow
    func elevatedCardStyle() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .foregroundColor(.lightText)
    }
    
    /// Compact card for inline elements
    func compactCardStyle() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground.opacity(0.6))
            )
            .foregroundColor(.lightText)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primaryGradient)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.pgPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pgPrimary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .pgAccent) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(color.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - View Extensions for Common Patterns

extension View {
    /// Apply standard page padding
    func pagePadding() -> some View {
        self.padding(.horizontal)
    }
    
    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, 8)
    }
    
    /// Apply shimmer loading effect
    func shimmerEffect(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ShimmerView()
                }
            }
        )
    }
}

// MARK: - Shimmer Effect

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase * geometry.size.width)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        }
    }
}

// MARK: - Typography Styles

extension Font {
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    static let appTitle = Font.system(size: 28, weight: .bold)
    static let appHeadline = Font.system(size: 20, weight: .semibold)
    static let appBody = Font.system(size: 16, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .regular)
}

// MARK: - Spacing Constants

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Shadow Styles

enum ShadowStyle {
    case light
    case medium
    case heavy
    
    var radius: CGFloat {
        switch self {
        case .light: return 5
        case .medium: return 8
        case .heavy: return 12
        }
    }
    
    var opacity: Double {
        switch self {
        case .light: return 0.1
        case .medium: return 0.3
        case .heavy: return 0.4
        }
    }
    
    var y: CGFloat {
        switch self {
        case .light: return 2
        case .medium: return 4
        case .heavy: return 6
        }
    }
}

extension View {
    func shadow(style: ShadowStyle) -> some View {
        self.shadow(
            color: Color.black.opacity(style.opacity),
            radius: style.radius,
            x: 0,
            y: style.y
        )
    }
}
