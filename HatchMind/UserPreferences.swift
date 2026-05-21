//
//  UserPreferences.swift
//  Hatch Mind
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TempUnit: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    var id: String { rawValue }
}

final class UserPreferences: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "hm_theme") }
    }
    @Published var tempUnit: TempUnit {
        didSet { UserDefaults.standard.set(tempUnit.rawValue, forKey: "hm_temp_unit") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "hm_logged_in") }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "hm_notifications") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "hm_sound") }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hm_haptics") }
    }
    @Published var reminderHour: Int {
        didSet { UserDefaults.standard.set(reminderHour, forKey: "hm_reminder_hour") }
    }
    @Published var profile: UserProfile {
        didSet {
            if let data = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(data, forKey: "hm_profile")
            }
        }
    }

    init() {
        self.theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "hm_theme") ?? "") ?? .system
        self.tempUnit = TempUnit(rawValue: UserDefaults.standard.string(forKey: "hm_temp_unit") ?? "") ?? .celsius
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "hm_logged_in")
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "hm_notifications") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "hm_sound") as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hm_haptics") as? Bool ?? true
        self.reminderHour = UserDefaults.standard.object(forKey: "hm_reminder_hour") as? Int ?? 9

        if let data = UserDefaults.standard.data(forKey: "hm_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = profile
        } else {
            self.profile = UserProfile.demo
        }
    }

    var effectiveColorScheme: ColorScheme {
        if let cs = theme.colorScheme { return cs }
        return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
    }

    func formattedTemp(_ celsius: Double) -> String {
        switch tempUnit {
        case .celsius:
            return String(format: "%.1f°C", celsius)
        case .fahrenheit:
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.1f°F", f)
        }
    }

    func formattedTempValue(_ celsius: Double) -> String {
        switch tempUnit {
        case .celsius:
            return String(format: "%.1f", celsius)
        case .fahrenheit:
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.1f", f)
        }
    }

    func tempUnitLabel() -> String { tempUnit.rawValue }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticsEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }

    func resetAll() {
        let keys = ["hm_theme", "hm_temp_unit", "hasCompletedOnboarding", "hm_logged_in",
                    "hm_notifications", "hm_sound", "hm_haptics", "hm_reminder_hour", "hm_profile",
                    "hm_incubations", "hm_readings", "hm_logs", "hm_candlings",
                    "hm_reminders", "hm_alerts", "hm_activity", "hm_tasks"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        theme = .system
        tempUnit = .celsius
        hasCompletedOnboarding = false
        isLoggedIn = false
        notificationsEnabled = true
        soundEnabled = true
        hapticsEnabled = true
        reminderHour = 9
        profile = UserProfile.demo
    }
}
