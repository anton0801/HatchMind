//
//  IncubationViews.swift
//  Hatch Mind
//

import SwiftUI

struct IncubationListView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack {
                        Text("Incubations")
                            .font(.hmTitle())
                            .foregroundColor(.hmTextPrimary)
                        Spacer()
                        Button {
                            prefs.haptic()
                            showAdd = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("New")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.hmTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(LinearGradient(colors: [.hmYellow, .hmYellowActive],
                                                       startPoint: .top, endPoint: .bottom))
                            .clipShape(Capsule())
                            .shadow(color: Color.hmYellow.opacity(0.4), radius: 8, y: 3)
                        }
                    }

                    if store.incubations.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.hmTextMuted.opacity(0.5))
                            Text("No incubations yet.")
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                        }.padding(.top, 60)
                    } else {
                        ForEach(store.incubations) { inc in
                            NavigationLink(destination: IncubationDetailView(incubation: inc)) {
                                IncubationRowCard(incubation: inc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) { AddIncubationView() }
    }
}

struct IncubationRowCard: View {
    let incubation: Incubation

    var body: some View {
        HMCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(incubation.birdType.emoji)
                        .font(.system(size: 30))
                        .frame(width: 50, height: 50)
                        .background(Color.hmBgSoft)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(incubation.name)
                            .font(.hmSection())
                            .foregroundColor(.hmTextPrimary)
                        Text("\(incubation.birdType.rawValue) • \(incubation.eggCount) eggs")
                            .font(.hmCaption())
                            .foregroundColor(.hmTextSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Day")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.hmTextSecondary)
                        Text("\(incubation.currentDay)/\(incubation.totalDays)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.hmYellowActive)
                    }
                }

                ProgressBar(progress: incubation.progress)

                HStack(spacing: 14) {
                    Label(incubation.stage.title, systemImage: incubation.stage.symbol)
                        .font(.hmCaption())
                        .foregroundColor(.hmOrange)
                    Spacer()
                    if incubation.isCompleted {
                        Label("Completed", systemImage: "checkmark.seal.fill")
                            .font(.hmCaption())
                            .foregroundColor(.hmGreen)
                    } else if incubation.isHatchDay {
                        Label("Hatch day!", systemImage: "sparkles")
                            .font(.hmCaption())
                            .foregroundColor(.hmGreen)
                    }
                }
            }
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.hmDivider)
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.hmYellow, .hmOrange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(progress), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Add Incubation
struct AddIncubationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences

    @State private var name: String = ""
    @State private var birdType: BirdType = .chicken
    @State private var startDate: Date = Date()
    @State private var eggCount: Int = 12
    @State private var notes: String = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        // Bird type
                        HMCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bird type")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(BirdType.allCases) { type in
                                            Button {
                                                prefs.haptic()
                                                birdType = type
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Text(type.emoji)
                                                        .font(.system(size: 26))
                                                    Text(type.rawValue)
                                                        .font(.hmCaption())
                                                        .foregroundColor(birdType == type ? .hmTextSecondary : .hmTextMuted)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 14)
                                                .background(birdType == type ? Color.hmYellow : Color.hmBgWarm)
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                Text("Incubation period: \(birdType.incubationDays) days")
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }

                        // Name
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextField("e.g. Spring Batch", text: $name)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        // Start date
                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start date")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                DatePicker("", selection: $startDate, in: ...Date(), displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .accentColor(.hmYellowActive)
                            }
                        }

                        // Egg count
                        HMCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Egg count")
                                        .font(.hmSection())
                                        .foregroundColor(.hmTextPrimary)
                                    Spacer()
                                    Text("\(eggCount)")
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(.hmYellowActive)
                                }
                                HStack {
                                    Button {
                                        prefs.haptic()
                                        if eggCount > 1 { eggCount -= 1 }
                                    } label: {
                                        Image(systemName: "minus")
                                            .frame(width: 36, height: 36)
                                            .background(Color.hmBgWarm)
                                            .foregroundColor(.hmTextSecondary)
                                            .clipShape(Circle())
                                    }
                                    Slider(value: Binding(
                                        get: { Double(eggCount) },
                                        set: { eggCount = Int($0) }
                                    ), in: 1...100, step: 1)
                                    .accentColor(.hmYellow)
                                    Button {
                                        prefs.haptic()
                                        if eggCount < 100 { eggCount += 1 }
                                    } label: {
                                        Image(systemName: "plus")
                                            .frame(width: 36, height: 36)
                                            .background(Color.hmBgWarm)
                                            .foregroundColor(.hmTextSecondary)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }

                        // Notes
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

                        if showError {
                            Text("Please enter a name.")
                                .font(.hmCaption())
                                .foregroundColor(.hmStatusError)
                        }

                        Button {
                            saveIncubation()
                        } label: {
                            Text("Start Incubation")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Incubation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveIncubation() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { showError = true }
            return
        }
        let inc = Incubation(name: name, birdType: birdType, startDate: startDate,
                             eggCount: eggCount, notes: notes)
        store.addIncubation(inc)
        prefs.haptic(.medium)
        dismiss()
    }
}

// MARK: - Detail
struct IncubationDetailView: View {
    let incubation: Incubation
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    @State private var showLog = false
    @State private var showCandling = false
    @State private var showReading = false
    @State private var confirmDelete = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    HMCard {
                        VStack(spacing: 14) {
                            Text(incubation.birdType.emoji)
                                .font(.system(size: 50))
                            Text(incubation.name)
                                .font(.hmHeader())
                                .foregroundColor(.hmTextPrimary)
                            Text("\(incubation.birdType.rawValue) • \(incubation.eggCount) eggs")
                                .font(.hmCaption())
                                .foregroundColor(.hmTextSecondary)

                            ZStack {
                                Circle()
                                    .stroke(Color.hmDivider, lineWidth: 12)
                                    .frame(width: 150, height: 150)
                                Circle()
                                    .trim(from: 0, to: incubation.progress)
                                    .stroke(LinearGradient(colors: [.hmYellow, .hmOrange],
                                                           startPoint: .leading, endPoint: .trailing),
                                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 150, height: 150)
                                    .rotationEffect(.degrees(-90))
                                VStack {
                                    Text("\(incubation.currentDay)")
                                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                                        .foregroundColor(.hmTextPrimary)
                                    Text("of \(incubation.totalDays)")
                                        .font(.hmCaption())
                                        .foregroundColor(.hmTextSecondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    actionGrid

                    HMCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Stage", systemImage: incubation.stage.symbol)
                                .font(.hmCaption())
                                .foregroundColor(.hmOrange)
                            Text(incubation.stage.title)
                                .font(.hmSection())
                                .foregroundColor(.hmTextPrimary)
                            Text(incubation.stage.description)
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !incubation.notes.isEmpty {
                        HMCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                Text(incubation.notes)
                                    .font(.hmBody())
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }
                    }

                    Button {
                        confirmDelete = true
                    } label: {
                        Label("Delete Incubation", systemImage: "trash")
                            .font(.hmCaption())
                            .foregroundColor(.hmStatusError)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.hmCardWarm)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .alert("Delete this incubation?", isPresented: $confirmDelete) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            store.deleteIncubation(incubation)
                            dismiss()
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Detail")
        .sheet(isPresented: $showLog) { AddDailyLogView(incubation: incubation) }
        .sheet(isPresented: $showCandling) { AddCandlingView(incubation: incubation) }
        .sheet(isPresented: $showReading) { AddReadingView(incubation: incubation) }
    }

    private var actionGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 10) {
            actionCard(title: "Log condition", icon: "thermometer", color: .hmYellowActive) {
                showReading = true
            }
            actionCard(title: "Daily log", icon: "square.and.pencil", color: .hmOrange) {
                showLog = true
            }
            actionCard(title: "Candling", icon: "flashlight.on.fill", color: .hmYellow) {
                showCandling = true
            }
            NavigationLink(destination: TimelineView(presetIncubation: incubation)) {
                actionCardLabel(title: "Timeline", icon: "calendar.badge.clock", color: .hmGreen)
            }
        }
    }

    private func actionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            prefs.haptic()
            action()
        } label: {
            actionCardLabel(title: title, icon: icon, color: color)
        }
        .buttonStyle(TapScaleStyle())
    }

    private func actionCardLabel(title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(color)
            }
            Text(title)
                .font(.hmBody())
                .foregroundColor(.hmTextPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.hmYellow.opacity(0.1), radius: 6, y: 2)
    }
}
