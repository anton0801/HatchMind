//
//  SettingsAndProfileViews.swift
//  Hatch Mind
//

import SwiftUI
import UserNotifications

// MARK: - More Hub
struct MoreView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore

    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("More")
                                .font(.hmTitle())
                                .foregroundColor(.hmTextPrimary)
                            Text("Tools, history & preferences")
                                .font(.hmCaption())
                                .foregroundColor(.hmTextSecondary)
                        }
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            ProfileAvatarBadge(name: prefs.profile.name)
                        }
                    }
                    .padding(.horizontal, 4)

                    HMCard {
                        VStack(spacing: 0) {
                            MoreRow(icon: "bell.badge.fill", title: "Reminders",
                                    subtitle: "\(store.reminders.count) configured",
                                    tint: .hmYellow,
                                    destination: AnyView(RemindersView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "app.badge", title: "Notifications",
                                    subtitle: prefs.notificationsEnabled ? "Enabled" : "Off",
                                    tint: .hmOrange,
                                    destination: AnyView(NotificationsView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "checklist", title: "Tasks",
                                    subtitle: "\(store.tasks.filter { !$0.isDone }.count) open",
                                    tint: .hmGreen,
                                    destination: AnyView(TasksView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "exclamationmark.triangle.fill", title: "Alerts",
                                    subtitle: "\(store.alerts.filter { !$0.isRead }.count) unread",
                                    tint: .hmTempHot,
                                    destination: AnyView(AlertsView()))
                        }
                    }

                    HMCard {
                        VStack(spacing: 0) {
                            MoreRow(icon: "chart.bar.fill", title: "Reports",
                                    subtitle: "Hatch analytics",
                                    tint: .hmYellow,
                                    destination: AnyView(ReportsView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "clock.arrow.circlepath", title: "History",
                                    subtitle: "\(store.incubations.filter { $0.isCompleted }.count) completed",
                                    tint: .hmOrange,
                                    destination: AnyView(HistoryView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "list.bullet.rectangle", title: "Activity History",
                                    subtitle: "\(store.activity.count) events",
                                    tint: .hmTempCool,
                                    destination: AnyView(ActivityHistoryView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "checkmark.seal.fill", title: "Results",
                                    subtitle: "Hatch outcomes",
                                    tint: .hmGreen,
                                    destination: AnyView(ResultsView()))
                        }
                    }

                    HMCard {
                        VStack(spacing: 0) {
                            MoreRow(icon: "person.crop.circle.fill", title: "Profile",
                                    subtitle: prefs.profile.farmName,
                                    tint: .hmYellow,
                                    destination: AnyView(ProfileView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "gearshape.fill", title: "Settings",
                                    subtitle: "Theme, units, notifications",
                                    tint: .hmTextSecondary,
                                    destination: AnyView(SettingsView()))
                            Divider().background(Color.hmDivider)
                            MoreRow(icon: "info.circle.fill", title: "About",
                                    subtitle: "Hatch Mind v1.0",
                                    tint: .hmOrange,
                                    destination: AnyView(AboutView()))
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
        }
        .navigationBarHidden(true)
    }
}

struct ProfileAvatarBadge: View {
    let name: String
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.hmYellow, .hmOrange],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
            Text(initials.isEmpty ? "HM" : initials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: Color.hmYellow.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.hmTextPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.hmTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.hmTextSecondary.opacity(0.6))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(TapScaleStyle())
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) var presentationMode

    @State private var showResetConfirm = false
    @State private var showResetDoneToast = false
    @State private var notifAuthDenied = false

    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 18) {
                    SectionHeader(title: "Appearance", icon: "paintbrush.fill")
                    HMCard {
                        VStack(spacing: 14) {
                            Text("Theme")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.hmTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 8) {
                                ForEach(AppTheme.allCases) { t in
                                    ThemeChip(theme: t, selected: prefs.theme == t) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            prefs.theme = t
                                        }
                                        prefs.haptic(.light)
                                        store.log(activity: "Changed theme to \(t.rawValue)")
                                    }
                                }
                            }

                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                Text("Theme applies instantly across the app.")
                                    .font(.system(size: 11))
                                Spacer()
                            }
                            .foregroundColor(.hmTextSecondary.opacity(0.8))
                        }
                    }

                    SectionHeader(title: "Units", icon: "thermometer.medium")
                    HMCard {
                        VStack(spacing: 12) {
                            Text("Temperature unit")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.hmTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 8) {
                                ForEach(TempUnit.allCases) { u in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            prefs.tempUnit = u
                                        }
                                        prefs.haptic(.light)
                                        store.log(activity: "Changed unit to \(u.rawValue)")
                                    } label: {
                                        Text(u.rawValue)
                                            .font(.system(size: 15, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(prefs.tempUnit == u ? Color.hmYellow : Color.hmCardSoft)
                                            )
                                            .foregroundColor(prefs.tempUnit == u ? .hmTextPrimary : .hmTextSecondary)
                                    }
                                    .buttonStyle(TapScaleStyle())
                                }
                            }

                            HStack {
                                Text("Sample reading")
                                    .font(.system(size: 12))
                                    .foregroundColor(.hmTextSecondary)
                                Spacer()
                                Text(prefs.formattedTemp(37.5))
                                    .font(.hmMono(14, weight: .bold))
                                    .foregroundColor(.hmTextPrimary)
                            }
                        }
                    }

                    SectionHeader(title: "Notifications", icon: "bell.fill")
                    HMCard {
                        VStack(spacing: 14) {
                            ToggleRow(title: "Notifications",
                                      subtitle: "Allow Hatch Mind to send reminders",
                                      icon: "bell.fill",
                                      tint: .hmYellow,
                                      isOn: Binding(
                                        get: { prefs.notificationsEnabled },
                                        set: { newValue in
                                            prefs.notificationsEnabled = newValue
                                            prefs.haptic(.light)
                                            if newValue {
                                                requestNotifAuth { granted in
                                                    if granted {
                                                        store.rescheduleAll()
                                                        store.log(activity: "Notifications enabled")
                                                    } else {
                                                        notifAuthDenied = true
                                                        prefs.notificationsEnabled = false
                                                    }
                                                }
                                            } else {
                                                store.cancelAllNotifications()
                                                store.log(activity: "Notifications disabled")
                                            }
                                        }))

                            Divider().background(Color.hmDivider)

                            ToggleRow(title: "Sound",
                                      subtitle: "Play sound with reminders",
                                      icon: "speaker.wave.2.fill",
                                      tint: .hmOrange,
                                      isOn: $prefs.soundEnabled)

                            Divider().background(Color.hmDivider)

                            ToggleRow(title: "Haptics",
                                      subtitle: "Tap feedback throughout the app",
                                      icon: "hand.tap.fill",
                                      tint: .hmGreen,
                                      isOn: $prefs.hapticsEnabled)

                            Divider().background(Color.hmDivider)

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.hmYellow)
                                    Text("Daily check time")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.hmTextPrimary)
                                    Spacer()
                                    Text(String(format: "%02d:00", prefs.reminderHour))
                                        .font(.hmMono(14, weight: .bold))
                                        .foregroundColor(.hmTextPrimary)
                                }
                                HStack(spacing: 10) {
                                    Button {
                                        if prefs.reminderHour > 0 {
                                            prefs.reminderHour -= 1
                                            prefs.haptic(.light)
                                            store.rescheduleAll()
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 13, weight: .bold))
                                            .frame(width: 36, height: 36)
                                            .background(Color.hmCardSoft)
                                            .foregroundColor(.hmTextPrimary)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(TapScaleStyle())

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.hmCardSoft)
                                                .frame(height: 6)
                                            Capsule()
                                                .fill(LinearGradient(colors: [.hmYellow, .hmOrange],
                                                                     startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * CGFloat(prefs.reminderHour) / 23.0, height: 6)
                                        }
                                        .frame(height: 36)
                                    }
                                    .frame(height: 36)

                                    Button {
                                        if prefs.reminderHour < 23 {
                                            prefs.reminderHour += 1
                                            prefs.haptic(.light)
                                            store.rescheduleAll()
                                        }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .bold))
                                            .frame(width: 36, height: 36)
                                            .background(Color.hmCardSoft)
                                            .foregroundColor(.hmTextPrimary)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(TapScaleStyle())
                                }
                            }
                        }
                    }

                    SectionHeader(title: "Account", icon: "person.fill")
                    HMCard {
                        VStack(spacing: 0) {
                            NavigationLink(destination: ProfileView()) {
                                HStack {
                                    ProfileAvatarBadge(name: prefs.profile.name)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prefs.profile.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.hmTextPrimary)
                                        Text(prefs.profile.email)
                                            .font(.system(size: 12))
                                            .foregroundColor(.hmTextSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.hmTextSecondary.opacity(0.6))
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(TapScaleStyle())
                        }
                    }

                    SectionHeader(title: "Data", icon: "tray.full.fill")
                    HMCard {
                        VStack(spacing: 12) {
                            HStack {
                                statBlock(label: "Incubations", value: "\(store.incubations.count)")
                                statBlock(label: "Readings", value: "\(store.readings.count)")
                                statBlock(label: "Logs", value: "\(store.logs.count)")
                            }

                            Button {
                                showResetConfirm = true
                                prefs.haptic(.medium)
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Reset all data")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.hmTempHot.opacity(0.12))
                                )
                                .foregroundColor(.hmTempHot)
                            }
                            .buttonStyle(TapScaleStyle())
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }

            if showResetDoneToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("All data reset")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.hmGreen))
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset all data?"),
                  message: Text("This permanently deletes incubations, readings, logs and settings."),
                  primaryButton: .destructive(Text("Reset")) {
                    store.cancelAllNotifications()
                    prefs.resetAll()
                    store.resetAll()
                    prefs.haptic(.heavy)
                    withAnimation { showResetDoneToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { showResetDoneToast = false }
                    }
                  },
                  secondaryButton: .cancel())
        }
    }

    func statBlock(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.hmTextPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.hmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.hmCardSoft)
        )
    }

    func requestNotifAuth(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.hmOrange)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.hmTextSecondary)
                .tracking(1.0)
            Spacer()
        }
        .padding(.horizontal, 6)
    }
}

struct ThemeChip: View {
    let theme: AppTheme
    let selected: Bool
    let action: () -> Void

    var icon: String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(theme.rawValue)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? Color.hmYellow : Color.hmCardSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected ? Color.hmOrange : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(selected ? .hmTextPrimary : .hmTextSecondary)
        }
        .buttonStyle(TapScaleStyle())
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(tint.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.hmTextPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.hmTextSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .hmOrange))
        }
    }
}

// MARK: - Profile
struct ProfileView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var farmName: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var savedFlash = false
    @State private var showLogOutConfirm = false

    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.hmYellow, .hmOrange],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .shadow(color: Color.hmYellow.opacity(0.4), radius: 16, x: 0, y: 8)
                            Text(initials())
                                .font(.system(size: 38, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        Text(name.isEmpty ? "Your name" : name)
                            .font(.hmTitle())
                            .foregroundColor(.hmTextPrimary)
                        Text(farmName.isEmpty ? "Add your farm" : farmName)
                            .font(.hmCaption())
                            .foregroundColor(.hmTextSecondary)
                    }
                    .padding(.top, 12)

                    HMCard {
                        VStack(spacing: 14) {
                            HMTextField(icon: "person.fill", placeholder: "Full name", text: $name)
                            HMTextField(icon: "house.fill", placeholder: "Farm name", text: $farmName)
                            HMTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                                .autocapitalization(.none)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.hmTextSecondary)
                                    Text("About")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.hmTextSecondary)
                                    Spacer()
                                }
                                ZStack(alignment: .topLeading) {
                                    if bio.isEmpty {
                                        Text("Tell us about your farm…")
                                            .font(.system(size: 14))
                                            .foregroundColor(.hmTextSecondary.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 6)
                                    }
                                    TextEditor(text: $bio)
                                        .frame(minHeight: 80)
                                        .padding(2)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.hmCardSoft)
                                )
                            }
                        }
                    }

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        let finalName = trimmed.isEmpty ? "Farmer" : trimmed
                        prefs.profile = UserProfile(name: finalName,
                                                    farmName: farmName.trimmingCharacters(in: .whitespaces),
                                                    email: email.trimmingCharacters(in: .whitespaces),
                                                    bio: bio)
                        store.log(activity: "Updated profile")
                        prefs.haptic(.medium)
                        withAnimation { savedFlash = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation { savedFlash = false }
                        }
                    } label: {
                        HStack {
                            Image(systemName: savedFlash ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                            Text(savedFlash ? "Saved" : "Save profile")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        showLogOutConfirm = true
                        prefs.haptic(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hmCardSoft)
                        )
                        .foregroundColor(.hmTextPrimary)
                    }
                    .buttonStyle(TapScaleStyle())

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = prefs.profile.name
            farmName = prefs.profile.farmName
            email = prefs.profile.email
            bio = prefs.profile.bio
        }
        .alert(isPresented: $showLogOutConfirm) {
            Alert(title: Text("Log out?"),
                  message: Text("You can sign back in with the demo account anytime."),
                  primaryButton: .destructive(Text("Log out")) {
                    prefs.isLoggedIn = false
                    prefs.hasCompletedOnboarding = true
                    store.log(activity: "Logged out")
                  },
                  secondaryButton: .cancel())
        }
    }

    func initials() -> String {
        let n = name.isEmpty ? "Hatch Mind" : name
        let parts = n.split(separator: " ").prefix(2)
        let s = parts.compactMap { $0.first }.map { String($0) }.joined().uppercased()
        return s.isEmpty ? "HM" : s
    }
}

// MARK: - Reminders
struct RemindersView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false

    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 14) {
                    HMCard {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.hmYellow.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.hmYellow)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(store.reminders.filter { $0.isEnabled }.count) active")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.hmTextPrimary)
                                Text("Reminders fire even when the app is closed")
                                    .font(.system(size: 11))
                                    .foregroundColor(.hmTextSecondary)
                            }
                            Spacer()
                        }
                    }

                    if !prefs.notificationsEnabled {
                        HMCard {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.hmOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notifications are off")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.hmTextPrimary)
                                    Text("Enable in Settings to receive reminders.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.hmTextSecondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    if store.reminders.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.reminders) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button {
                showAdd = true
                prefs.haptic(.light)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.hmYellow)
            }
        )
        .sheet(isPresented: $showAdd) {
            AddReminderView()
                .environmentObject(prefs)
                .environmentObject(store)
        }
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.hmYellow.opacity(0.18))
                    .frame(width: 110, height: 110)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.hmYellow)
            }
            Text("No reminders yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.hmTextPrimary)
            Text("Schedule egg turning, candling, and condition checks.")
                .font(.system(size: 12))
                .foregroundColor(.hmTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                showAdd = true
                prefs.haptic(.light)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add reminder")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.vertical, 30)
    }
}

struct ReminderRow: View {
    let reminder: ReminderItem
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: reminder.time)
    }

    var body: some View {
        HMCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(reminder.type.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: reminder.type.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(reminder.type.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.hmTextPrimary)
                    HStack(spacing: 10) {
                        Label(timeString, systemImage: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.hmTextSecondary)
                        if reminder.repeatDaily {
                            Label("Daily", systemImage: "repeat")
                                .font(.system(size: 11))
                                .foregroundColor(.hmTextSecondary)
                        }
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    Toggle("", isOn: Binding(
                        get: { reminder.isEnabled },
                        set: { _ in
                            store.toggleReminder(reminder)
                            prefs.haptic(.light)
                        }))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .hmOrange))
                    Button {
                        store.deleteReminder(reminder)
                        prefs.haptic(.medium)
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.hmTextSecondary.opacity(0.7))
                    }
                }
            }
        }
    }
}

struct AddReminderView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) var presentationMode

    @State private var type: ReminderType = .turning
    @State private var title: String = ""
    @State private var time: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatsDaily: Bool = true
    @State private var incubationId: UUID? = nil

    var body: some View {
        NavigationView {
            HMScreen {
                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeader(title: "Reminder type", icon: "bell.fill")
                        HMCard {
                            VStack(spacing: 8) {
                                ForEach(ReminderType.allCases) { rt in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            type = rt
                                            if title.isEmpty || ReminderType.allCases.map({ $0.defaultTitle }).contains(title) {
                                                title = rt.defaultTitle
                                            }
                                        }
                                        prefs.haptic(.light)
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(rt.tint.opacity(0.18))
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: rt.icon)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(rt.tint)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(rt.defaultTitle)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.hmTextPrimary)
                                                Text(rt.helperText)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.hmTextSecondary)
                                            }
                                            Spacer()
                                            if type == rt {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.hmGreen)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(TapScaleStyle())
                                }
                            }
                        }

                        SectionHeader(title: "Details", icon: "square.and.pencil")
                        HMCard {
                            VStack(spacing: 14) {
                                HMTextField(icon: "textformat", placeholder: "Title", text: $title)

                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.hmYellow)
                                    Text("Time")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.hmTextPrimary)
                                    Spacer()
                                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }

                                Toggle(isOn: $repeatsDaily) {
                                    HStack {
                                        Image(systemName: "repeat")
                                            .foregroundColor(.hmOrange)
                                        Text("Repeat daily")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.hmTextPrimary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .hmOrange))

                                if !store.incubations.filter({ !$0.isCompleted }).isEmpty {
                                    Divider().background(Color.hmDivider)
                                    Text("Link to incubation (optional)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.hmTextSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            chip(label: "None", selected: incubationId == nil) {
                                                incubationId = nil
                                            }
                                            ForEach(store.incubations.filter { !$0.isCompleted }) { inc in
                                                chip(label: inc.name, selected: incubationId == inc.id) {
                                                    incubationId = inc.id
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            saveReminder()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save reminder")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New reminder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(.hmTextSecondary)
            )
            .onAppear {
                if title.isEmpty { title = type.defaultTitle }
            }
        }
    }

    func chip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Color.hmYellow : Color.hmCardSoft)
                )
                .foregroundColor(selected ? .hmTextPrimary : .hmTextSecondary)
        }
        .buttonStyle(TapScaleStyle())
    }

    func saveReminder() {
        let reminder = ReminderItem(id: UUID(),
                                    title: title.trimmingCharacters(in: .whitespaces),
                                    type: type,
                                    time: time,
                                    isEnabled: true,
                                    repeatDaily: repeatsDaily,
                                    incubationId: incubationId)
        store.addReminder(reminder)
        prefs.haptic(.medium)
        store.log(activity: "Added reminder \(reminder.title)")
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Notifications
struct NotificationsView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @State private var pendingCount: Int = 0
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 14) {
                    HMCard {
                        VStack(spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(statusColor.opacity(0.18))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: statusIcon)
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(statusColor)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(statusTitle)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.hmTextPrimary)
                                    Text(statusSubtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(.hmTextSecondary)
                                }
                                Spacer()
                            }

                            if authStatus == .notDetermined {
                                Button {
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                        DispatchQueue.main.async {
                                            refreshStatus()
                                            if granted {
                                                prefs.notificationsEnabled = true
                                                store.rescheduleAll()
                                            }
                                        }
                                    }
                                } label: {
                                    Text("Enable notifications")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }

                    HMCard {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Pending in iOS")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.hmTextSecondary)
                                Spacer()
                                Text("\(pendingCount)")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.hmTextPrimary)
                            }
                            Divider().background(Color.hmDivider)
                            HStack(spacing: 8) {
                                Button {
                                    store.rescheduleAll()
                                    prefs.haptic(.light)
                                    refreshPending()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Reschedule")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.hmYellow.opacity(0.2)))
                                    .foregroundColor(.hmTextPrimary)
                                }
                                .buttonStyle(TapScaleStyle())

                                Button {
                                    store.cancelAllNotifications()
                                    prefs.haptic(.medium)
                                    refreshPending()
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.bin.fill")
                                        Text("Cancel all")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.hmTempHot.opacity(0.15)))
                                    .foregroundColor(.hmTempHot)
                                }
                                .buttonStyle(TapScaleStyle())
                            }
                        }
                    }

                    SectionHeader(title: "In-app alerts", icon: "exclamationmark.bubble.fill")
                    if store.alerts.isEmpty {
                        HMCard {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.hmGreen)
                                Text("No alerts. Conditions look good.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.hmTextSecondary)
                                Spacer()
                            }
                        }
                    } else {
                        ForEach(store.alerts.prefix(8)) { alert in
                            AlertRowCompact(alert: alert)
                        }
                        if store.alerts.count > 8 {
                            NavigationLink(destination: AlertsView()) {
                                Text("See all \(store.alerts.count) alerts")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.hmOrange)
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshStatus()
            refreshPending()
        }
    }

    var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return .hmGreen
        case .denied: return .hmTempHot
        default: return .hmYellow
        }
    }
    var statusIcon: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "bell.fill"
        case .denied: return "bell.slash.fill"
        default: return "bell.badge.fill"
        }
    }
    var statusTitle: String {
        switch authStatus {
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .denied: return "Denied"
        default: return "Not requested"
        }
    }
    var statusSubtitle: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "Hatch Mind can deliver reminders."
        case .denied: return "Allow notifications in iOS Settings."
        default: return "Tap below to allow notifications."
        }
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { authStatus = settings.authorizationStatus }
        }
    }
    func refreshPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            DispatchQueue.main.async { pendingCount = reqs.count }
        }
    }
}

struct AlertRowCompact: View {
    let alert: ConditionAlert
    @EnvironmentObject var store: DataStore

    var body: some View {
        HMCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(alert.severity.color)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.hmTextPrimary)
                    Text(alert.message)
                        .font(.system(size: 11))
                        .foregroundColor(.hmTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if !alert.isRead {
                    Circle().fill(Color.hmYellow).frame(width: 8, height: 8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.markAlertRead(alert)
            }
        }
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        HMScreen {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.hmYellow, .hmOrange],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .shadow(color: Color.hmYellow.opacity(0.4), radius: 16, x: 0, y: 8)
                            Text("🐣")
                                .font(.system(size: 56))
                        }
                        Text("Hatch Mind")
                            .font(.hmTitle())
                            .foregroundColor(.hmTextPrimary)
                        Text("Version 1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.hmTextSecondary)
                    }
                    .padding(.top, 16)

                    HMCard {
                        VStack(spacing: 14) {
                            Text("Smart incubation companion")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.hmTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Track every day of incubation, control temperature and humidity, schedule turning reminders, log candling sessions, and celebrate hatch day with confidence.")
                                .font(.system(size: 13))
                                .foregroundColor(.hmTextSecondary)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    HMCard {
                        VStack(alignment: .leading, spacing: 10) {
                            featureRow(icon: "calendar", title: "Smart timeline", color: .hmYellow)
                            featureRow(icon: "thermometer.medium", title: "Conditions monitor", color: .hmOrange)
                            featureRow(icon: "bell.badge.fill", title: "Turning reminders", color: .hmGreen)
                            featureRow(icon: "eye.fill", title: "Candling log", color: .hmTempCool)
                            featureRow(icon: "chart.bar.fill", title: "Hatch reports", color: .hmTempHot)
                        }
                    }

                    Text("Built with care for poultry farmers.")
                        .font(.system(size: 11))
                        .foregroundColor(.hmTextSecondary.opacity(0.7))

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    func featureRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.hmTextPrimary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.hmGreen)
        }
        .padding(.vertical, 4)
    }
}
