//
//  LogsAndAlertsViews.swift
//  Hatch Mind
//

import SwiftUI

// MARK: - Daily Log List
struct DailyLogView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    let incubation: Incubation
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    let entries = store.logs(for: incubation)
                    if entries.isEmpty {
                        Text("No daily log entries yet.")
                            .font(.hmBody())
                            .foregroundColor(.hmTextSecondary)
                            .padding(.top, 80)
                    } else {
                        ForEach(entries) { entry in
                            HMCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Day \(entry.day)")
                                            .font(.hmSection())
                                            .foregroundColor(.hmYellowActive)
                                        Spacer()
                                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.hmCaption())
                                            .foregroundColor(.hmTextSecondary)
                                    }
                                    if !entry.note.isEmpty {
                                        Text(entry.note)
                                            .font(.hmBody())
                                            .foregroundColor(.hmTextPrimary)
                                    }
                                    HStack(spacing: 14) {
                                        if entry.turned {
                                            Label("Turned", systemImage: "arrow.triangle.2.circlepath")
                                                .font(.hmCaption())
                                                .foregroundColor(.hmGreen)
                                        }
                                        if entry.candled {
                                            Label("Candled", systemImage: "flashlight.on.fill")
                                                .font(.hmCaption())
                                                .foregroundColor(.hmYellowActive)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Daily Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.hmYellowActive)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddDailyLogView(incubation: incubation) }
    }
}

struct AddDailyLogView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    let incubation: Incubation

    @State private var note: String = ""
    @State private var turned: Bool = true
    @State private var candled: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Day \(incubation.currentDay)")
                                    .font(.hmHeader())
                                    .foregroundColor(.hmTextPrimary)
                                Text(incubation.stage.title)
                                    .font(.hmCaption())
                                    .foregroundColor(.hmOrange)
                            }
                        }

                        HMCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Notes")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextEditor(text: $note)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        HMCard {
                            VStack(spacing: 10) {
                                Toggle(isOn: $turned) {
                                    Label("Eggs turned", systemImage: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.hmTextPrimary)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .hmYellow))
                                Divider().background(Color.hmDivider)
                                Toggle(isOn: $candled) {
                                    Label("Candled today", systemImage: "flashlight.on.fill")
                                        .foregroundColor(.hmTextPrimary)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .hmYellow))
                            }
                        }

                        Button {
                            let entry = DailyLogEntry(date: Date(), day: incubation.currentDay,
                                                      note: note, turned: turned, candled: candled,
                                                      incubationId: incubation.id)
                            store.addLog(entry)
                            prefs.haptic(.medium)
                            dismiss()
                        } label: { Text("Save Log") }
                        .buttonStyle(PrimaryButtonStyle())

                        Button { dismiss() } label: { Text("Cancel") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Candling
struct CandlingView: View {
    @EnvironmentObject var store: DataStore
    let incubation: Incubation
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    let records = store.candlings(for: incubation)
                    if records.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "flashlight.on.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.hmYellow)
                            Text("No candling records yet.")
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                            Text("Candle eggs around day 7, 14, and 18 to check development.")
                                .font(.hmCaption())
                                .foregroundColor(.hmTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }.padding(.top, 60)
                    } else {
                        ForEach(records) { rec in
                            HMCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Day \(rec.day)")
                                            .font(.hmSection())
                                            .foregroundColor(.hmYellowActive)
                                        Spacer()
                                        Text(rec.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.hmCaption())
                                            .foregroundColor(.hmTextSecondary)
                                    }
                                    HStack(spacing: 12) {
                                        statTag("Fertile", "\(rec.fertileCount)", .hmGreen)
                                        statTag("Infertile", "\(rec.infertileCount)", .hmYellowActive)
                                        statTag("Dead", "\(rec.deadCount)", .hmStatusError)
                                    }
                                    if !rec.notes.isEmpty {
                                        Text(rec.notes)
                                            .font(.hmBody())
                                            .foregroundColor(.hmTextPrimary)
                                    }
                                }
                            }
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("Candling Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.hmYellowActive)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddCandlingView(incubation: incubation) }
    }

    private func statTag(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.hmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AddCandlingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    let incubation: Incubation

    @State private var fertile: Int = 0
    @State private var infertile: Int = 0
    @State private var dead: Int = 0
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Candling — Day \(incubation.currentDay)")
                                    .font(.hmHeader())
                                    .foregroundColor(.hmTextPrimary)
                                Text("Total eggs: \(incubation.eggCount)")
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }
                        countCard(title: "Fertile (developing)", value: $fertile, color: .hmGreen, max: incubation.eggCount)
                        countCard(title: "Infertile (clear)", value: $infertile, color: .hmYellowActive, max: incubation.eggCount)
                        countCard(title: "Dead embryos", value: $dead, color: .hmStatusError, max: incubation.eggCount)

                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        Button {
                            let rec = CandlingRecord(date: Date(), day: incubation.currentDay,
                                                     fertileCount: fertile, infertileCount: infertile,
                                                     deadCount: dead, notes: notes,
                                                     incubationId: incubation.id)
                            store.addCandling(rec)
                            prefs.haptic(.medium)
                            dismiss()
                        } label: { Text("Save Candling") }
                        .buttonStyle(PrimaryButtonStyle())

                        Button { dismiss() } label: { Text("Cancel") }
                            .buttonStyle(SecondaryButtonStyle())
                    }.padding(16)
                }
            }
            .navigationTitle("Candling")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func countCard(title: String, value: Binding<Int>, color: Color, max: Int) -> some View {
        HMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.hmSection())
                        .foregroundColor(.hmTextPrimary)
                    Spacer()
                    Text("\(value.wrappedValue)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(color)
                }
                HStack {
                    Button {
                        if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 32, height: 32)
                            .background(Color.hmBgWarm)
                            .foregroundColor(.hmTextSecondary)
                            .clipShape(Circle())
                    }
                    Slider(value: Binding(get: { Double(value.wrappedValue) },
                                          set: { value.wrappedValue = Int($0) }),
                           in: 0...Double(max), step: 1)
                        .accentColor(color)
                    Button {
                        if value.wrappedValue < max { value.wrappedValue += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 32)
                            .background(Color.hmBgWarm)
                            .foregroundColor(.hmTextSecondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

// MARK: - Hatch Day
struct HatchDayView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    let incubation: Incubation
    @State private var hatched: Int
    @State private var didCelebrate = false
    @State private var sparkleAngle: Double = 0
    @Environment(\.dismiss) var dismiss

    init(incubation: Incubation) {
        self.incubation = incubation
        _hatched = State(initialValue: incubation.hatchedCount)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.hmBgPrimary, .hmYellowGlow.opacity(0.4)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZStack {
                        ForEach(0..<8) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 16))
                                .foregroundColor(.hmYellow)
                                .offset(x: cos(Double(i) * .pi / 4 + sparkleAngle) * 110,
                                        y: sin(Double(i) * .pi / 4 + sparkleAngle) * 110)
                                .opacity(0.8)
                        }
                        Text("🐣")
                            .font(.system(size: 90))
                    }
                    .frame(height: 220)
                    .padding(.top, 12)
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            sparkleAngle = .pi * 2
                        }
                    }
                    .onDisappear { sparkleAngle = 0 }

                    Text("Hatch day!")
                        .font(.hmTitle())
                        .foregroundColor(.hmTextPrimary)
                    Text(incubation.name)
                        .font(.hmSection())
                        .foregroundColor(.hmTextSecondary)

                    HMCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Chicks hatched")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                Spacer()
                                Text("\(hatched) / \(incubation.eggCount)")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(.hmYellowActive)
                            }
                            HStack {
                                Button {
                                    if hatched > 0 { hatched -= 1 }
                                    prefs.haptic()
                                } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 36, height: 36)
                                        .background(Color.hmBgWarm)
                                        .foregroundColor(.hmTextSecondary)
                                        .clipShape(Circle())
                                }
                                Slider(value: Binding(get: { Double(hatched) },
                                                      set: { hatched = Int($0) }),
                                       in: 0...Double(incubation.eggCount), step: 1)
                                .accentColor(.hmYellow)
                                Button {
                                    if hatched < incubation.eggCount { hatched += 1 }
                                    prefs.haptic()
                                } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 36, height: 36)
                                        .background(Color.hmBgWarm)
                                        .foregroundColor(.hmTextSecondary)
                                        .clipShape(Circle())
                                }
                            }
                            ProgressBar(progress: Double(hatched) / Double(max(incubation.eggCount, 1)))
                                .padding(.top, 4)
                        }
                    }

                    HMCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Hatch rate", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.hmCaption())
                                .foregroundColor(.hmOrange)
                            Text(String(format: "%.0f%%", Double(hatched) / Double(max(incubation.eggCount, 1)) * 100))
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.hmGreen)
                        }
                    }

                    Button {
                        var inc = incubation
                        inc.hatchedCount = hatched
                        inc.isCompleted = true
                        store.updateIncubation(inc)
                        store.log(activity: ActivityEntry(date: Date(),
                                                          title: "Hatch completed",
                                                          detail: "\(hatched)/\(inc.eggCount) chicks",
                                                          symbol: "sparkles"))
                        prefs.haptic(.heavy)
                        dismiss()
                    } label: { Text("Complete Incubation") }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(16)
            }
        }
        .navigationTitle("Hatch Day")
    }
}

// MARK: - Results
struct ResultsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    let completed = store.incubations.filter { $0.isCompleted }
                    if completed.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.hmTextMuted.opacity(0.5))
                            Text("No completed incubations yet.")
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                        }.padding(.top, 80)
                    } else {
                        // Summary
                        let totalEggs = completed.reduce(0) { $0 + $1.eggCount }
                        let totalHatched = completed.reduce(0) { $0 + $1.hatchedCount }
                        let rate = totalEggs > 0 ? Double(totalHatched) / Double(totalEggs) * 100 : 0

                        HMCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Overall results")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                HStack {
                                    summaryStat("Hatched", "\(totalHatched)", .hmGreen)
                                    summaryStat("Eggs", "\(totalEggs)", .hmYellowActive)
                                    summaryStat("Rate", String(format: "%.0f%%", rate), .hmOrange)
                                }
                            }
                        }

                        ForEach(completed) { inc in
                            HMCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(inc.name)
                                            .font(.hmSection())
                                            .foregroundColor(.hmTextPrimary)
                                        Spacer()
                                        Text(inc.birdType.emoji)
                                    }
                                    HStack {
                                        summaryStat("Hatched", "\(inc.hatchedCount)", .hmGreen)
                                        summaryStat("Total", "\(inc.eggCount)", .hmYellowActive)
                                        summaryStat("Rate",
                                                    String(format: "%.0f%%", Double(inc.hatchedCount) / Double(max(inc.eggCount, 1)) * 100),
                                                    .hmOrange)
                                    }
                                }
                            }
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("Results")
    }

    private func summaryStat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.hmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - History
struct HistoryView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    if store.incubations.isEmpty {
                        Text("No history yet.")
                            .font(.hmBody())
                            .foregroundColor(.hmTextSecondary)
                            .padding(.top, 80)
                    } else {
                        ForEach(store.incubations.sorted(by: { $0.startDate > $1.startDate })) { inc in
                            NavigationLink(destination: IncubationDetailView(incubation: inc)) {
                                IncubationRowCard(incubation: inc)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("History")
    }
}

// MARK: - Reports
struct ReportsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    HMCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active incubations")
                                .font(.hmSection())
                                .foregroundColor(.hmTextPrimary)
                            let active = store.incubations.filter { !$0.isCompleted }
                            HStack {
                                Text("\(active.count)")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.hmYellowActive)
                                Spacer()
                                Image(systemName: "tray.full.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.hmYellow.opacity(0.6))
                            }
                        }
                    }

                    HMCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Conditions average (7 days)")
                                .font(.hmSection())
                                .foregroundColor(.hmTextPrimary)
                            let recent = store.readings.filter { $0.date > Date().addingTimeInterval(-7 * 86400) }
                            let avgT = recent.isEmpty ? 0 : recent.map(\.temperatureC).reduce(0, +) / Double(recent.count)
                            let avgH = recent.isEmpty ? 0 : recent.map(\.humidity).reduce(0, +) / Double(recent.count)
                            HStack(spacing: 12) {
                                statBox("Temp avg", recent.isEmpty ? "—" : prefs.formattedTemp(avgT), .hmYellowActive)
                                statBox("Humidity avg", recent.isEmpty ? "—" : "\(Int(avgH))%", .hmHumNorm)
                            }
                            statBox("Readings", "\(recent.count)", .hmOrange)
                        }
                    }

                    HMCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Alerts")
                                .font(.hmSection())
                                .foregroundColor(.hmTextPrimary)
                            HStack(spacing: 12) {
                                statBox("Critical",
                                        "\(store.alerts.filter { $0.severity == .critical }.count)",
                                        .hmStatusError)
                                statBox("Warnings",
                                        "\(store.alerts.filter { $0.severity == .warning }.count)",
                                        .hmYellowActive)
                            }
                        }
                    }

                    NavigationLink(destination: ResultsView()) {
                        HMCard {
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                    .foregroundColor(.hmGreen)
                                Text("View Hatch Results")
                                    .font(.hmBody())
                                    .foregroundColor(.hmTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }
                    }.buttonStyle(.plain)

                    NavigationLink(destination: HistoryView()) {
                        HMCard {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.hmOrange)
                                Text("History")
                                    .font(.hmBody())
                                    .foregroundColor(.hmTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }.padding(16)
            }
        }
        .navigationTitle("Reports")
    }

    private func statBox(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.hmCaption())
                .foregroundColor(.hmTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Alerts
struct AlertsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    if store.alerts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.hmGreen)
                            Text("No alerts.")
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                        }.padding(.top, 80)
                    } else {
                        ForEach(store.alerts) { alert in
                            Button {
                                store.markAlertRead(alert)
                            } label: {
                                HMCard {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(alert.severity.color.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: alert.severity.symbol)
                                                .foregroundColor(alert.severity.color)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(alert.title)
                                                    .font(.hmBody())
                                                    .foregroundColor(.hmTextPrimary)
                                                if !alert.isRead {
                                                    Circle().fill(Color.hmStatusError).frame(width: 8, height: 8)
                                                }
                                            }
                                            Text(alert.message)
                                                .font(.hmCaption())
                                                .foregroundColor(.hmTextSecondary)
                                            Text(alert.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 10))
                                                .foregroundColor(.hmTextMuted)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("Alerts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !store.alerts.isEmpty {
                    Button("Clear all") {
                        store.clearAllAlerts()
                    }
                    .foregroundColor(.hmStatusError)
                }
            }
        }
    }
}

// MARK: - Tasks
struct TasksView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    if store.tasks.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checklist")
                                .font(.system(size: 50))
                                .foregroundColor(.hmTextMuted.opacity(0.5))
                            Text("No tasks yet.")
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                        }.padding(.top, 80)
                    } else {
                        ForEach(store.tasks) { task in
                            HMCard {
                                HStack(spacing: 12) {
                                    Button {
                                        store.toggleTask(task)
                                        prefs.haptic()
                                    } label: {
                                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22))
                                            .foregroundColor(task.isDone ? .hmGreen : .hmYellowActive)
                                    }
                                    .buttonStyle(.plain)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.hmBody())
                                            .foregroundColor(.hmTextPrimary)
                                            .strikethrough(task.isDone)
                                        if !task.detail.isEmpty {
                                            Text(task.detail)
                                                .font(.hmCaption())
                                                .foregroundColor(.hmTextSecondary)
                                                .lineLimit(2)
                                        }
                                        Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 11))
                                            .foregroundColor(.hmOrange)
                                    }
                                    Spacer()
                                    Button {
                                        store.deleteTask(task)
                                        prefs.haptic()
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.hmStatusError.opacity(0.7))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.hmYellowActive)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView() }
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences

    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextField("e.g. Check water level", text: $title)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detail")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextEditor(text: $detail)
                                    .frame(minHeight: 70)
                                    .padding(8)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due date")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .accentColor(.hmYellowActive)
                            }
                        }
                        if showError {
                            Text("Please enter a title.")
                                .font(.hmCaption())
                                .foregroundColor(.hmStatusError)
                        }
                        Button {
                            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { showError = true }
                                return
                            }
                            let task = InspectionTask(title: title, detail: detail,
                                                      dueDate: dueDate, isDone: false,
                                                      incubationId: store.primaryIncubation?.id)
                            store.addTask(task)
                            prefs.haptic(.medium)
                            dismiss()
                        } label: { Text("Add Task") }
                        .buttonStyle(PrimaryButtonStyle())

                        Button { dismiss() } label: { Text("Cancel") }
                            .buttonStyle(SecondaryButtonStyle())
                    }.padding(16)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Activity History
struct ActivityHistoryView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    if store.activity.isEmpty {
                        Text("No activity yet.")
                            .font(.hmBody())
                            .foregroundColor(.hmTextSecondary)
                            .padding(.top, 80)
                    } else {
                        ForEach(store.activity) { entry in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.hmYellow.opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: entry.symbol)
                                        .foregroundColor(.hmYellowActive)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.hmBody())
                                        .foregroundColor(.hmTextPrimary)
                                    Text(entry.detail)
                                        .font(.hmCaption())
                                        .foregroundColor(.hmTextSecondary)
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 10))
                                        .foregroundColor(.hmTextMuted)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.hmCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }.padding(16)
            }
        }
        .navigationTitle("Activity")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !store.activity.isEmpty {
                    Button("Clear") { store.clearActivity() }
                        .foregroundColor(.hmStatusError)
                }
            }
        }
    }
}
