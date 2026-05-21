//
//  DesignSystem.swift
//  Hatch Mind
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let hmBgPrimary = Color(hex: "FFFBEB")
    static let hmBgSoft = Color(hex: "FEF3C7")
    static let hmBgWarm = Color(hex: "FFF7ED")
    static let hmCard = Color(hex: "FFFFFF")
    static let hmCardWarm = Color(hex: "FFF1E6")
    static let hmDivider = Color(hex: "FDE68A")
    static let hmDividerStrong = Color(hex: "FCD34D")

    // Primary accent - warmth / incubation
    static let hmYellow = Color(hex: "FACC15")
    static let hmYellowActive = Color(hex: "F59E0B")
    static let hmYellowGlow = Color(hex: "FDE047")

    // Secondary accent - process
    static let hmOrange = Color(hex: "F97316")
    static let hmOrangeSoft = Color(hex: "FB923C")
    static let hmOrangeGlow = Color(hex: "FDBA74")

    // Health
    static let hmGreen = Color(hex: "22C55E")
    static let hmGreenSoft = Color(hex: "4ADE80")

    // Temperature
    static let hmTempCold = Color(hex: "60A5FA")
    static let hmTempNorm = Color(hex: "22C55E")
    static let hmTempWarm = Color(hex: "FACC15")
    static let hmTempHot = Color(hex: "EF4444")

    // Humidity
    static let hmHumLow = Color(hex: "93C5FD")
    static let hmHumNorm = Color(hex: "22C55E")
    static let hmHumHigh = Color(hex: "06B6D4")

    // Chick accent
    static let hmChick = Color(hex: "FDE047")
    static let hmChickSoft = Color(hex: "FFF7AE")

    // Statuses
    static let hmStatusOk = Color(hex: "22C55E")
    static let hmStatusWarn = Color(hex: "FACC15")
    static let hmStatusError = Color(hex: "EF4444")

    // Text
    static let hmTextPrimary = Color(hex: "78350F")
    static let hmTextSecondary = Color(hex: "92400E")
    static let hmTextMuted = Color(hex: "A16207")

    // Timeline
    static let hmDayNormal = Color(hex: "FDE68A")
    static let hmDayCurrent = Color(hex: "FACC15")
    static let hmDayDone = Color(hex: "22C55E")

    // Dark variants
    static let hmDarkBg = Color(hex: "1C1410")
    static let hmDarkCard = Color(hex: "2A1F18")
    static let hmDarkText = Color(hex: "FEF3C7")

    // Aliases
    static let hmCardSoft = Color(hex: "FFF1E6")
    static let hmTempCool = Color(hex: "60A5FA")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// MARK: - Adaptive colors
struct ThemeColors {
    let isDark: Bool

    var background: Color { isDark ? .hmDarkBg : .hmBgPrimary }
    var card: Color { isDark ? .hmDarkCard : .hmCard }
    var textPrimary: Color { isDark ? .hmDarkText : .hmTextPrimary }
    var textSecondary: Color { isDark ? Color(hex: "FCD34D") : .hmTextSecondary }
}

// MARK: - Typography
extension Font {
    static func hmTitle() -> Font { .system(size: 32, weight: .heavy, design: .rounded) }
    static func hmHeader() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func hmSection() -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func hmBody() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func hmCaption() -> Font { .system(size: 13, weight: .medium, design: .rounded) }
    static func hmMono() -> Font { .system(size: 28, weight: .heavy, design: .rounded) }
    static func hmMono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Custom Buttons
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(Color.hmTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.hmYellow, .hmYellowActive],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.hmYellow.opacity(0.4), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(Color.hmTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.hmBgWarm)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.hmDividerStrong, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct TapScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card Container
struct HMCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(Color.hmCard)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.hmYellow.opacity(0.12), radius: 14, y: 4)
    }
}

// MARK: - Adaptive helpers
struct HMScreen<Content: View>: View {
    @EnvironmentObject var prefs: UserPreferences
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            (prefs.effectiveColorScheme == .dark ? Color.hmDarkBg : Color.hmBgPrimary)
                .ignoresSafeArea()
            content
        }
    }
}
