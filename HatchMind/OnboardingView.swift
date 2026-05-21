//
//  OnboardingView.swift
//  Hatch Mind
//

import SwiftUI
import CoreMotion

struct OnboardingView: View {
    @EnvironmentObject var prefs: UserPreferences
    @Environment(\.dismiss) var dismiss
    @State private var pageIndex: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.hmBgPrimary, .hmBgSoft],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        prefs.haptic()
                        finish()
                    }
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary)
                    .padding(12)
                    .background(Color.hmBgWarm)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                TabView(selection: $pageIndex) {
                    Onboard1View().tag(0)
                    Onboard2View().tag(1)
                    Onboard3View().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: pageIndex)

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { idx in
                        Capsule()
                            .fill(idx == pageIndex ? Color.hmYellow : Color.hmDivider)
                            .frame(width: idx == pageIndex ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: pageIndex)
                    }
                }
                .padding(.bottom, 12)

                // Next / Start
                Button {
                    prefs.haptic()
                    if pageIndex < 2 {
                        withAnimation { pageIndex += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(pageIndex == 2 ? "Get Started" : "Next")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    func finish() {
        prefs.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Page 1 — Tap-to-burst particles
struct Onboard1View: View {
    @State private var burstParticles: [BurstParticle] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var hint: Bool = false
    @State private var isVisible = true

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // background ring
                Circle()
                    .stroke(Color.hmDivider, lineWidth: 2)
                    .frame(width: 240, height: 240)
                Circle()
                    .stroke(Color.hmYellow.opacity(0.5), lineWidth: 2)
                    .frame(width: 180, height: 180)

                // burst particles
                ForEach(burstParticles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .offset(x: p.offsetX, y: p.offsetY)
                        .opacity(p.opacity)
                }

                // tap target
                Button {
                    triggerBurst()
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.hmYellow, .hmYellowActive],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.hmYellow.opacity(0.5), radius: 14)
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.hmTextSecondary)
                    }
                    .scaleEffect(iconScale)
                }
                .buttonStyle(.plain)

                if hint {
                    Text("Tap me!")
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.hmBgWarm)
                        .clipShape(Capsule())
                        .offset(y: 90)
                }
            }
            .frame(height: 260)
            .padding(.top, 12)

            VStack(spacing: 12) {
                Text("Track incubation days")
                    .font(.hmTitle())
                    .foregroundColor(.hmTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Every clutch is timed precisely.\nStart, monitor, and never lose a day.")
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            isVisible = true
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                hint.toggle()
            }
        }
        .onDisappear {
            isVisible = false
            burstParticles = []
            iconScale = 1.0
            hint = false
        }
    }

    func triggerBurst() {
        guard isVisible else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconScale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
        }

        // create particles
        var newParticles: [BurstParticle] = []
        for i in 0..<14 {
            let angle = Double(i) * (.pi * 2 / 14)
            let dist = CGFloat.random(in: 90...140)
            newParticles.append(BurstParticle(
                offsetX: 0, offsetY: 0, targetX: cos(angle) * dist, targetY: sin(angle) * dist,
                size: CGFloat.random(in: 6...12),
                color: [.hmYellow, .hmOrange, .hmChick, .hmYellowGlow].randomElement() ?? .hmYellow,
                opacity: 1.0
            ))
        }
        burstParticles = newParticles

        for i in 0..<burstParticles.count {
            withAnimation(.easeOut(duration: 0.7)) {
                burstParticles[i].offsetX = burstParticles[i].targetX
                burstParticles[i].offsetY = burstParticles[i].targetY
                burstParticles[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            burstParticles.removeAll()
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    var offsetX: CGFloat
    var offsetY: CGFloat
    var targetX: CGFloat
    var targetY: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Page 2 — Drag thermometer
struct Onboard2View: View {
    @State private var dragY: CGFloat = 0
    @State private var lastDragY: CGFloat = 0
    @State private var isVisible = true
    @State private var pulse: Bool = false

    private var temp: Double { 36.0 + (1.0 - max(0.0, min(1.0, (dragY + 100) / 200.0))) * 4.0 }
    private var tempColor: Color {
        if temp < 36.5 { return .hmTempCold }
        if temp < 37.4 { return .hmTempCold.opacity(0.7) }
        if temp <= 37.8 { return .hmTempNorm }
        if temp < 38.5 { return .hmTempWarm }
        return .hmTempHot
    }
    private var tempLabel: String {
        if temp < 36.5 { return "Too cold" }
        if temp < 37.4 { return "Cool" }
        if temp <= 37.8 { return "Perfect" }
        if temp < 38.5 { return "Warm" }
        return "Too hot"
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // thermometer body
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.hmCard)
                    .frame(width: 60, height: 220)
                    .shadow(color: Color.hmYellow.opacity(0.15), radius: 8, y: 3)

                // mercury
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [tempColor.opacity(0.7), tempColor],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 32, height: max(40, min(190, 100 - dragY)))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: dragY)
                }
                .frame(width: 60, height: 220)

                // bulb
                Circle()
                    .fill(tempColor)
                    .frame(width: 70, height: 70)
                    .offset(y: 130)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .shadow(color: tempColor.opacity(0.5), radius: 12)

                // drag knob
                ZStack {
                    Capsule()
                        .fill(Color.hmYellow)
                        .frame(width: 110, height: 36)
                        .overlay(
                            Capsule().stroke(Color.hmYellowActive, lineWidth: 2)
                        )
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.hmTextSecondary)
                }
                .offset(x: 0, y: dragY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let v = lastDragY + value.translation.height
                            dragY = max(-100, min(100, v))
                        }
                        .onEnded { _ in
                            lastDragY = dragY
                        }
                )
            }
            .frame(height: 260)

            VStack(spacing: 6) {
                Text(String(format: "%.1f°C", temp))
                    .font(.hmMono())
                    .foregroundColor(tempColor)
                Text(tempLabel)
                    .font(.hmCaption())
                    .foregroundColor(.hmTextSecondary)
            }

            VStack(spacing: 12) {
                Text("Control temperature")
                    .font(.hmTitle())
                    .foregroundColor(.hmTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Drag the slider — see how every degree matters.\nWe alert you when readings drift.")
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            isVisible = true
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear {
            isVisible = false
            pulse = false
            dragY = 0
            lastDragY = 0
        }
    }
}

// MARK: - Page 3 — Scroll-driven hatch progress
struct Onboard3View: View {
    @State private var progress: Double = 0.0
    @State private var isVisible = true
    @State private var celebrated: Bool = false
    @State private var sparkOpacity: Double = 0
    @State private var hatchScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // glow when complete
                Circle()
                    .fill(Color.hmYellow.opacity(0.25))
                    .frame(width: 240, height: 240)
                    .scaleEffect(celebrated ? 1.1 : 0.9)
                    .opacity(celebrated ? 0.9 : 0.4)
                    .blur(radius: 20)

                // ring
                Circle()
                    .stroke(Color.hmDivider, lineWidth: 14)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.hmYellow, .hmOrange, .hmGreen],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(progress * 21))")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundColor(.hmTextPrimary)
                    Text("of 21 days")
                        .font(.hmCaption())
                        .foregroundColor(.hmTextSecondary)
                }
                .scaleEffect(hatchScale)

                // sparkles when complete
                if celebrated {
                    ForEach(0..<8) { i in
                        let angle = Double(i) * (.pi / 4)
                        Image(systemName: "sparkle")
                            .font(.system(size: 18))
                            .foregroundColor(.hmYellow)
                            .offset(x: cos(angle) * 130, y: sin(angle) * 130)
                            .opacity(sparkOpacity)
                    }
                }
            }
            .frame(height: 260)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = -value.translation.height / 200.0
                        progress = max(0, min(1, progress + delta * 0.02))
                    }
            )

            // hint slider
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text("Swipe up to advance days")
            }
            .font(.hmCaption())
            .foregroundColor(.hmTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.hmBgWarm)
            .clipShape(Capsule())

            VStack(spacing: 12) {
                Text("Get perfect hatch results")
                    .font(.hmTitle())
                    .foregroundColor(.hmTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Stage by stage, day by day.\nSee development unfold and prepare for hatch day.")
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onChange(of: progress) { newValue in
            if newValue >= 1.0 && !celebrated {
                celebrated = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    hatchScale = 1.15
                    sparkOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        hatchScale = 1.0
                    }
                }
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
            }
        }
        .onAppear {
            isVisible = true
            // animated hint - small auto progress
            withAnimation(.easeInOut(duration: 1.2)) {
                progress = 0.15
            }
        }
        .onDisappear {
            isVisible = false
            progress = 0
            celebrated = false
            sparkOpacity = 0
            hatchScale = 1.0
        }
    }
}
