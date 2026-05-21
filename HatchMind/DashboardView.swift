//
//  DashboardView.swift
//  Hatch Mind
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var pulseGlow = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let inc = store.primaryIncubation {
                    daysHero(for: inc)
                    statRow(for: inc)
                    stageCard(for: inc)
                    todayTasksCard()
                    recentAlertsCard(for: inc)
                } else {
                    emptyState
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.hmBgPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) {
            AddIncubationView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
        .onDisappear { pulseGlow = false }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(prefs.profile.name.components(separatedBy: " ").first ?? "Farmer")")
                    .font(.hmHeader())
                    .foregroundColor(.hmTextPrimary)
                Text(prefs.profile.farmName)
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary.opacity(0.85))
            }
            Spacer()
            Button {
                prefs.haptic()
                showAdd = true
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.hmYellow, .hmYellowActive],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.hmYellow.opacity(0.4), radius: 8, y: 3)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.hmTextSecondary)
                }
            }
            .buttonStyle(TapScaleStyle())
        }
        .padding(.top, 8)
    }

    // MARK: - Days Hero
    private func daysHero(for inc: Incubation) -> some View {
        HMCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(inc.name)
                        .font(.hmSection())
                        .foregroundColor(.hmTextPrimary)
                    Spacer()
                    Text(inc.birdType.emoji)
                        .font(.system(size: 24))
                }

                ZStack {
                    Circle()
                        .stroke(Color.hmDivider, lineWidth: 14)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: inc.progress)
                        .stroke(
                            AngularGradient(colors: [.hmYellow, .hmOrange, .hmYellow],
                                            center: .center),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.hmYellow.opacity(pulseGlow ? 0.6 : 0.2), radius: 8)

                    VStack(spacing: 2) {
                        Text("Day")
                            .font(.hmCaption())
                            .foregroundColor(.hmTextSecondary)
                        Text("\(inc.currentDay)")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundColor(.hmTextPrimary)
                        Text("of \(inc.totalDays)")
                            .font(.hmCaption())
                            .foregroundColor(.hmTextSecondary.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

                HStack {
                    Label(formattedDate(inc.startDate), systemImage: "calendar")
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                    Spacer()
                    Label("Hatch \(formattedDate(inc.expectedHatchDate))", systemImage: "checkmark.seal.fill")
                        .font(.hmCaption())
                        .foregroundColor(.hmGreen)
                }
            }
        }
    }

    // MARK: - Stat Row
    private func statRow(for inc: Incubation) -> some View {
        HStack(spacing: 12) {
            statTile(icon: "thermometer.medium", title: "Temp",
                     value: tempValueString(for: inc),
                     color: tempColor(for: inc))
            statTile(icon: "drop.fill", title: "Humidity",
                     value: humidityString(for: inc),
                     color: humidityColor(for: inc))
            statTile(icon: "tray.full.fill", title: "Eggs",
                     value: "\(inc.eggCount)",
                     color: .hmOrange)
        }
    }

    private func statTile(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.18))
                    .clipShape(Circle())
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.hmTextPrimary)
            Text(title)
                .font(.hmCaption())
                .foregroundColor(.hmTextSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.hmYellow.opacity(0.1), radius: 8, y: 3)
    }

    private func tempValueString(for inc: Incubation) -> String {
        guard let r = store.latestReading(for: inc) else { return "—" }
        return prefs.formattedTempValue(r.temperatureC) + prefs.tempUnitLabel()
    }
    private func humidityString(for inc: Incubation) -> String {
        guard let r = store.latestReading(for: inc) else { return "—" }
        return "\(Int(r.humidity))%"
    }
    private func tempColor(for inc: Incubation) -> Color {
        guard let r = store.latestReading(for: inc) else { return .hmYellow }
        if r.temperatureC < 36.5 { return .hmTempCold }
        if r.temperatureC <= 37.8 { return .hmTempNorm }
        if r.temperatureC < 38.5 { return .hmTempWarm }
        return .hmTempHot
    }
    private func humidityColor(for inc: Incubation) -> Color {
        guard let r = store.latestReading(for: inc) else { return .hmHumNorm }
        if r.humidity < 45 { return .hmHumLow }
        if r.humidity > 65 { return .hmHumHigh }
        return .hmHumNorm
    }

    // MARK: - Stage card
    private func stageCard(for inc: Incubation) -> some View {
        HMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: inc.stage.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.hmOrange)
                    Text("Current stage")
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                    Spacer()
                    Text("Day \(inc.currentDay)")
                        .font(.hmCaption())
                        .foregroundColor(.hmYellowActive)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.hmBgSoft)
                        .clipShape(Capsule())
                }
                Text(inc.stage.title)
                    .font(.hmSection())
                    .foregroundColor(.hmTextPrimary)
                Text(inc.stage.description)
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Tasks
    private func todayTasksCard() -> some View {
        let openTasks = store.tasks.filter { !$0.isDone }.prefix(3)
        return HMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Today's tasks")
                        .font(.hmSection())
                        .foregroundColor(.hmTextPrimary)
                    Spacer()
                    NavigationLink(destination: TasksView()) {
                        Text("All")
                            .font(.hmCaption())
                            .foregroundColor(.hmYellowActive)
                    }
                }
                if openTasks.isEmpty {
                    Text("All clear — no tasks pending.")
                        .font(.hmBody())
                        .foregroundColor(.hmTextSecondary.opacity(0.8))
                } else {
                    ForEach(Array(openTasks)) { task in
                        Button {
                            store.toggleTask(task)
                            prefs.haptic()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(task.isDone ? .hmGreen : .hmYellowActive)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.hmBody())
                                        .foregroundColor(.hmTextPrimary)
                                    Text(task.detail)
                                        .font(.hmCaption())
                                        .foregroundColor(.hmTextSecondary.opacity(0.8))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Alerts
    private func recentAlertsCard(for inc: Incubation) -> some View {
        let unread = store.alerts(for: inc).filter { !$0.isRead }.prefix(3)
        return HMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Alerts")
                        .font(.hmSection())
                        .foregroundColor(.hmTextPrimary)
                    Spacer()
                    NavigationLink(destination: AlertsView()) {
                        Text("All")
                            .font(.hmCaption())
                            .foregroundColor(.hmYellowActive)
                    }
                }
                if unread.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.hmGreen)
                        Text("Conditions look great.")
                            .font(.hmBody())
                            .foregroundColor(.hmTextSecondary)
                    }
                } else {
                    ForEach(Array(unread)) { alert in
                        HStack(spacing: 10) {
                            Image(systemName: alert.severity.symbol)
                                .foregroundColor(alert.severity.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(.hmBody())
                                    .foregroundColor(.hmTextPrimary)
                                Text(alert.message)
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.hmYellow.opacity(0.2))
                    .frame(width: 130, height: 130)
                EggShape()
                    .fill(LinearGradient(colors: [.hmChickSoft, .hmYellow],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 80, height: 100)
            }
            .padding(.top, 40)
            Text("No incubations yet")
                .font(.hmHeader())
                .foregroundColor(.hmTextPrimary)
            Text("Tap + to add your first batch.")
                .font(.hmBody())
                .foregroundColor(.hmTextSecondary)
            Button {
                showAdd = true
            } label: { Text("Add Incubation") }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }
}
