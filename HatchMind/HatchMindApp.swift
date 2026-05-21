//
//  HatchMindApp.swift
//  Hatch Mind
//

import SwiftUI
import UserNotifications

@main
struct HatchMindApp: App {
    @StateObject private var prefs = UserPreferences()
    @StateObject private var store = DataStore()

    init() {
        // Configure default appearance for navigation
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.hmTextPrimary)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(Color.hmTextPrimary)
        ]
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(prefs)
                .environmentObject(store)
                .preferredColorScheme(prefs.theme.colorScheme)
                .onAppear {
                    if prefs.notificationsEnabled {
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            if settings.authorizationStatus == .notDetermined {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                            }
                        }
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                LaunchView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else if !prefs.hasCompletedOnboarding {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity
                    ))
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: splashFinished)
        .animation(.easeInOut(duration: 0.4), value: prefs.hasCompletedOnboarding)
    }
}
