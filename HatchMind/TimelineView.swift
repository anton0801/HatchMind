//
//  TimelineView.swift
//  Hatch Mind
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    @State private var selectedIncId: UUID?
    var presetIncubation: Incubation?

    init(presetIncubation: Incubation? = nil) {
        self.presetIncubation = presetIncubation
    }

    var selectedInc: Incubation? {
        if let preset = presetIncubation {
            return store.incubations.first { $0.id == preset.id }
        }
        if let id = selectedIncId {
            return store.incubations.first { $0.id == id }
        }
        return store.primaryIncubation
    }

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Timeline")
                        .font(.hmTitle())
                        .foregroundColor(.hmTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    if !store.incubations.isEmpty && presetIncubation == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.incubations) { inc in
                                    Button {
                                        prefs.haptic()
                                        selectedIncId = inc.id
                                    } label: {
                                        Text(inc.name)
                                            .font(.hmCaption())
                                            .foregroundColor((selectedInc?.id == inc.id) ? .hmTextSecondary : .hmTextMuted)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background((selectedInc?.id == inc.id) ? Color.hmYellow : Color.hmBgWarm)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if let inc = selectedInc {
                        timelineHero(for: inc)
                            .padding(.horizontal, 16)

                        stagesSection(for: inc)
                            .padding(.horizontal, 16)

                        daysSection(for: inc)
                            .padding(.horizontal, 16)
                    } else {
                        Text("No incubations yet.")
                            .font(.hmBody())
                            .foregroundColor(.hmTextSecondary)
                            .padding(.horizontal, 16)
                    }
                    Spacer(minLength: 30)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func timelineHero(for inc: Incubation) -> some View {
        HMCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(inc.birdType.emoji).font(.system(size: 28))
                    VStack(alignment: .leading) {
                        Text(inc.name)
                            .font(.hmSection())
                            .foregroundColor(.hmTextPrimary)
                        Text("Day \(inc.currentDay) of \(inc.totalDays)")
                            .font(.hmCaption())
                            .foregroundColor(.hmTextSecondary)
                    }
                    Spacer()
                }
                ProgressBar(progress: inc.progress)
            }
        }
    }

    private func stagesSection(for inc: Incubation) -> some View {
        let stages = DevelopmentStage.standard(totalDays: inc.totalDays)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Development stages")
                .font(.hmSection())
                .foregroundColor(.hmTextPrimary)
            ForEach(Array(stages.enumerated()), id: \.element.id) { idx, stage in
                stageRow(stage: stage, isCurrent: stage.dayRange.contains(inc.currentDay), isDone: inc.currentDay > stage.dayRange.upperBound)
            }
        }
    }

    private func stageRow(stage: DevelopmentStage, isCurrent: Bool, isDone: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.hmYellow : (isDone ? Color.hmGreen : Color.hmDivider))
                    .frame(width: 36, height: 36)
                Image(systemName: isDone ? "checkmark" : stage.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isCurrent || isDone ? .hmTextSecondary : .hmTextMuted)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.title)
                        .font(.hmBody())
                        .foregroundColor(.hmTextPrimary)
                    if isCurrent {
                        Text("NOW")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(.hmTextSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.hmYellow)
                            .clipShape(Capsule())
                    }
                }
                Text("Day \(stage.dayRange.lowerBound)–\(stage.dayRange.upperBound)")
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary)
                Text(stage.description)
                    .font(.hmCaption())
                    .foregroundColor(.hmTextMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            isCurrent ?
            RoundedRectangle(cornerRadius: 16).stroke(Color.hmYellow, lineWidth: 2) : nil
        )
    }

    private func daysSection(for inc: Incubation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Days")
                .font(.hmSection())
                .foregroundColor(.hmTextPrimary)
            let cols = [GridItem(.adaptive(minimum: 56), spacing: 10)]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(1...inc.totalDays, id: \.self) { day in
                    DayChip(day: day, currentDay: inc.currentDay)
                }
            }
        }
    }
}

struct DayChip: View {
    let day: Int
    let currentDay: Int

    private var color: Color {
        if day < currentDay { return .hmDayDone }
        if day == currentDay { return .hmDayCurrent }
        return .hmDayNormal
    }

    private var textColor: Color {
        if day < currentDay { return .white }
        if day == currentDay { return .hmTextSecondary }
        return .hmTextSecondary.opacity(0.7)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("Day")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(textColor.opacity(0.8))
            Text("\(day)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(textColor)
        }
        .frame(width: 56, height: 56)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            day == currentDay ?
            RoundedRectangle(cornerRadius: 12).stroke(Color.hmYellowActive, lineWidth: 2) : nil
        )
        .scaleEffect(day == currentDay ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: day == currentDay)
    }
}
