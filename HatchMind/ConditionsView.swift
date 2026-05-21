//
//  ConditionsView.swift
//  Hatch Mind
//

import SwiftUI

struct ConditionsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    @State private var selectedIncId: UUID?
    @State private var showAddReading = false

    var selectedInc: Incubation? {
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
                    HStack {
                        Text("Conditions")
                            .font(.hmTitle())
                            .foregroundColor(.hmTextPrimary)
                        Spacer()
                        Button {
                            prefs.haptic()
                            showAddReading = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Log")
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
                    .padding(.horizontal, 16)

                    if !store.incubations.isEmpty {
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
                        gauges(for: inc)
                            .padding(.horizontal, 16)

                        history(for: inc)
                            .padding(.horizontal, 16)
                    } else {
                        emptyState.padding(.horizontal, 16)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddReading) {
            if let inc = selectedInc {
                AddReadingView(incubation: inc)
            }
        }
    }

    private func gauges(for inc: Incubation) -> some View {
        HStack(spacing: 12) {
            tempGauge(for: inc)
            humidityGauge(for: inc)
        }
    }

    private func tempGauge(for inc: Incubation) -> some View {
        let reading = store.latestReading(for: inc)
        let temp = reading?.temperatureC ?? 37.5
        let normRange = inc.birdType.idealTempC

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.medium")
                    .foregroundColor(tempColor(temp: temp, range: normRange))
                Text("Temperature")
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary)
                Spacer()
            }
            ZStack {
                Circle()
                    .stroke(Color.hmDivider, lineWidth: 10)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: tempProgress(temp))
                    .stroke(tempColor(temp: temp, range: normRange),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(prefs.formattedTempValue(temp))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.hmTextPrimary)
                    Text(prefs.tempUnitLabel())
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            Text(tempStatusLabel(temp: temp, range: normRange))
                .font(.hmCaption())
                .foregroundColor(tempColor(temp: temp, range: normRange))
                .frame(maxWidth: .infinity)
            Text("Ideal \(prefs.formattedTempValue(normRange.lowerBound))–\(prefs.formattedTempValue(normRange.upperBound))\(prefs.tempUnitLabel())")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.hmTextMuted)
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.hmYellow.opacity(0.1), radius: 6, y: 2)
    }

    private func humidityGauge(for inc: Incubation) -> some View {
        let reading = store.latestReading(for: inc)
        let h = reading?.humidity ?? 53
        let normRange = inc.birdType.idealHumidity

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(humidityColor(h: h, range: normRange))
                Text("Humidity")
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary)
                Spacer()
            }
            ZStack {
                Circle()
                    .stroke(Color.hmDivider, lineWidth: 10)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: min(1, max(0, h / 100.0)))
                    .stroke(humidityColor(h: h, range: normRange),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(h))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.hmTextPrimary)
                    Text("%")
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            Text(humidityStatusLabel(h: h, range: normRange))
                .font(.hmCaption())
                .foregroundColor(humidityColor(h: h, range: normRange))
                .frame(maxWidth: .infinity)
            Text("Ideal \(Int(normRange.lowerBound))–\(Int(normRange.upperBound))%")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.hmTextMuted)
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.hmYellow.opacity(0.1), radius: 6, y: 2)
    }

    private func tempProgress(_ temp: Double) -> Double {
        let val = (temp - 35.0) / 5.0
        return min(1, max(0, val))
    }

    private func tempColor(temp: Double, range: ClosedRange<Double>) -> Color {
        if temp < range.lowerBound - 0.5 { return .hmTempCold }
        if temp < range.lowerBound { return .hmTempCold.opacity(0.7) }
        if range.contains(temp) { return .hmTempNorm }
        if temp < range.upperBound + 0.5 { return .hmTempWarm }
        return .hmTempHot
    }

    private func tempStatusLabel(temp: Double, range: ClosedRange<Double>) -> String {
        if temp < range.lowerBound - 0.5 { return "Too cold" }
        if temp < range.lowerBound { return "Cool" }
        if range.contains(temp) { return "Optimal" }
        if temp < range.upperBound + 0.5 { return "Warm" }
        return "Too hot"
    }

    private func humidityColor(h: Double, range: ClosedRange<Double>) -> Color {
        if h < range.lowerBound - 5 { return .hmHumLow }
        if range.contains(h) { return .hmHumNorm }
        if h > range.upperBound + 5 { return .hmHumHigh }
        return .hmYellowActive
    }

    private func humidityStatusLabel(h: Double, range: ClosedRange<Double>) -> String {
        if h < range.lowerBound - 5 { return "Too low" }
        if h < range.lowerBound { return "Low" }
        if range.contains(h) { return "Optimal" }
        if h > range.upperBound + 5 { return "Too high" }
        return "High"
    }

    private func history(for inc: Incubation) -> some View {
        let readings = Array(store.readings(for: inc).prefix(15))
        return VStack(alignment: .leading, spacing: 8) {
            Text("Recent readings")
                .font(.hmSection())
                .foregroundColor(.hmTextPrimary)
            if readings.isEmpty {
                Text("No readings yet — tap Log to add one.")
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary)
                    .padding(12)
            } else {
                // simple line chart
                if readings.count >= 2 {
                    ConditionsChart(readings: readings.reversed())
                        .frame(height: 130)
                        .padding(12)
                        .background(Color.hmCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                ForEach(readings) { r in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedDate(r.date))
                                .font(.hmBody())
                                .foregroundColor(.hmTextPrimary)
                            if !r.note.isEmpty {
                                Text(r.note)
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(prefs.formattedTemp(r.temperatureC))
                                .font(.hmBody())
                                .foregroundColor(.hmTextSecondary)
                            Text("\(Int(r.humidity))%")
                                .font(.hmCaption())
                                .foregroundColor(.hmHumNorm)
                        }
                    }
                    .padding(12)
                    .background(Color.hmCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "thermometer.snowflake")
                .font(.system(size: 50))
                .foregroundColor(.hmTextMuted.opacity(0.5))
            Text("Add an incubation to start tracking conditions.")
                .font(.hmBody())
                .foregroundColor(.hmTextSecondary)
                .multilineTextAlignment(.center)
        }.padding(.top, 60)
            .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: d)
    }
}

// Simple SwiftUI chart for temp/humidity history
struct ConditionsChart: View {
    let readings: [ConditionReading]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // grid
                ForEach(0..<4) { i in
                    Path { path in
                        let y = CGFloat(i) * geo.size.height / 3
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Color.hmDivider.opacity(0.5), lineWidth: 1)
                }

                // temp line
                tempLine(in: geo.size)
                    .stroke(LinearGradient(colors: [.hmYellow, .hmOrange],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                // humidity line
                humidityLine(in: geo.size)
                    .stroke(Color.hmHumNorm,
                            style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                Label("Temp", systemImage: "circle.fill")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.hmYellowActive)
                Label("Humidity", systemImage: "circle.fill")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.hmHumNorm)
            }
        }
    }

    private func tempLine(in size: CGSize) -> Path {
        var path = Path()
        guard !readings.isEmpty else { return path }
        let minT = 36.0, maxT = 39.0
        let step = readings.count > 1 ? size.width / CGFloat(readings.count - 1) : 0
        for (i, r) in readings.enumerated() {
            let x = step * CGFloat(i)
            let y = size.height - (CGFloat(r.temperatureC - minT) / CGFloat(maxT - minT)) * size.height
            let p = CGPoint(x: x, y: max(0, min(size.height, y)))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }

    private func humidityLine(in size: CGSize) -> Path {
        var path = Path()
        guard !readings.isEmpty else { return path }
        let step = readings.count > 1 ? size.width / CGFloat(readings.count - 1) : 0
        for (i, r) in readings.enumerated() {
            let x = step * CGFloat(i)
            let y = size.height - (CGFloat(r.humidity / 100.0)) * size.height
            let p = CGPoint(x: x, y: max(0, min(size.height, y)))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
}

// MARK: - Add reading
struct AddReadingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var prefs: UserPreferences
    let incubation: Incubation

    @State private var temp: Double = 37.5
    @State private var humidity: Double = 55
    @State private var note: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        HMCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "thermometer.medium")
                                        .foregroundColor(.hmYellowActive)
                                    Text("Temperature")
                                        .font(.hmSection())
                                        .foregroundColor(.hmTextPrimary)
                                    Spacer()
                                    Text(prefs.formattedTemp(temp))
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(.hmYellowActive)
                                }
                                Slider(value: $temp, in: 35...40, step: 0.1)
                                    .accentColor(.hmYellow)
                                Text("Ideal \(prefs.formattedTemp(incubation.birdType.idealTempC.lowerBound))–\(prefs.formattedTemp(incubation.birdType.idealTempC.upperBound))")
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }

                        HMCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(.hmHumNorm)
                                    Text("Humidity")
                                        .font(.hmSection())
                                        .foregroundColor(.hmTextPrimary)
                                    Spacer()
                                    Text("\(Int(humidity))%")
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(.hmHumNorm)
                                }
                                Slider(value: $humidity, in: 20...90, step: 1)
                                    .accentColor(.hmHumNorm)
                                Text("Ideal \(Int(incubation.birdType.idealHumidity.lowerBound))–\(Int(incubation.birdType.idealHumidity.upperBound))%")
                                    .font(.hmCaption())
                                    .foregroundColor(.hmTextSecondary)
                            }
                        }

                        HMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Note")
                                    .font(.hmSection())
                                    .foregroundColor(.hmTextPrimary)
                                TextEditor(text: $note)
                                    .frame(minHeight: 70)
                                    .padding(8)
                                    .background(Color.hmBgWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        Button {
                            let r = ConditionReading(date: Date(), temperatureC: temp,
                                                     humidity: humidity, note: note,
                                                     incubationId: incubation.id)
                            store.addReading(r, for: incubation)
                            prefs.haptic(.medium)
                            dismiss()
                        } label: {
                            Text("Save Reading")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            dismiss()
                        } label: { Text("Cancel") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Log Conditions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
