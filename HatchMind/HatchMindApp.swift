import SwiftUI
import UserNotifications
import Combine

@main
struct HatchMindApp: App {
    @StateObject private var prefs = UserPreferences()
    @StateObject private var store = DataStore()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(prefs)
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @State private var splashFinished = false

    init() {
        // Configure default appearance for navigation
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.hmTextPrimary)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(Color.hmTextPrimary)
        ]
    }
    
    var body: some View {
        ZStack {
            if !prefs.hasCompletedOnboarding {
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
        .animation(.easeInOut(duration: 0.4), value: prefs.hasCompletedOnboarding)
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


final class NotificationConsentEmitter: ConsentEmitter {
    
    func emit() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future<Bool, Never> { promise in
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, error in
                    if let error = error {
                    }
                    DispatchQueue.main.async {
                        promise(.success(granted))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func armPushBeacon() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

