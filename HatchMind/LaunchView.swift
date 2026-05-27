import SwiftUI
import Combine
import Network

struct LaunchView: View {

    @State private var isVisible = true
    @State private var bgPhase: CGFloat = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var glowScale: CGFloat = 0.6
    @State private var glowOpacity: Double = 0.0
    @State private var eggScale: CGFloat = 0.3
    @State private var eggOpacity: Double = 0.0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var eggRotate: Double = -8
    @State private var crackProgress: CGFloat = 0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 14
    @State private var subOpacity: Double = 0.0
    @StateObject private var viewModel = HatchMindViewModel()
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    @State private var particles: [Particle] = (0..<14).map { _ in Particle.random() }
    @State private var particleTime: CGFloat = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Phase 1 - Animated warm gradient background
                backgroundLayer

                // Floating warm particles (midground)
                particlesLayer

                // Phase 2 - pulsing glow + egg + crack
                ZStack {
                    pulsingGlow
                    eggIcon
                }
                .scaleEffect(exitScale)
                .opacity(exitOpacity)
                
                NavigationLink(
                    destination: HatchMindWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }

                // Phase 3 - title
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("Hatch Mind")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(.hmTextPrimary)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)

                        Text("Control incubation process")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.hmTextSecondary.opacity(0.85))
                            .opacity(subOpacity)
                    }
                    .padding(.bottom, 90)
                    .opacity(exitOpacity)
                }
                
                if viewModel.showOfflineView {
                    VStack {
                        Spacer()
                        Image("error")
                            .resizable()
                            .frame(width: 200, height: 150)
                        Spacer()
                        HStack {
                            Spacer()
                        }
                    }
                    .background(
                        Color.black
                            .opacity(0.7)
                    )
                }
            }
            .onAppear { runAnimation() }
            .onDisappear { stopAllAnimations() }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                HatchMindConsentView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Background gradient layer
    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [.hmBgPrimary, .hmBgSoft, .hmBgWarm],
                    startPoint: UnitPoint(x: 0.2 + 0.3 * bgPhase, y: 0.1),
                    endPoint: UnitPoint(x: 0.9 - 0.3 * bgPhase, y: 1.0)
                )

                // soft warm radial highlight
                RadialGradient(
                    colors: [Color.hmYellowGlow.opacity(0.35), .clear],
                    center: UnitPoint(x: 0.5, y: 0.45),
                    startRadius: 30,
                    endRadius: 280
                )

                RadialGradient(
                    colors: [Color.hmOrangeGlow.opacity(0.18), .clear],
                    center: UnitPoint(x: 0.85 - 0.3 * bgPhase, y: 0.8),
                    startRadius: 10,
                    endRadius: 220
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: - Particles
    private var particlesLayer: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(LinearGradient(colors: [.hmYellowGlow, .hmOrangeSoft.opacity(0.6)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x * geo.size.width,
                            y: ((p.y + particleTime * p.speed).truncatingRemainder(dividingBy: 1.0)) * geo.size.height
                        )
                        .opacity(p.opacity)
                        .blur(radius: 0.5)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Pulsing glow ring (heartbeat)
    private var pulsingGlow: some View {
        ZStack {
            Circle()
                .fill(Color.hmYellow.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(glowScale + 0.4)
                .opacity(glowOpacity * 0.8)
                .blur(radius: 12)

            Circle()
                .fill(Color.hmOrange.opacity(0.18))
                .frame(width: 160, height: 160)
                .scaleEffect(glowScale + 0.2)
                .opacity(glowOpacity * 0.6)
                .blur(radius: 8)

            Circle()
                .stroke(Color.hmYellow.opacity(0.35), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(glowScale)
                .opacity(glowOpacity * 0.5)
        }
    }

    // MARK: - Egg with crack
    private var eggIcon: some View {
        ZStack {
            // Egg body
            EggShape()
                .fill(
                    LinearGradient(colors: [.hmChickSoft, .hmYellowGlow, .hmYellow],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 110, height: 140)
                .shadow(color: Color.hmYellowActive.opacity(0.3), radius: 18, y: 6)

            // Crack overlay
            CrackShape(progress: crackProgress)
                .stroke(Color.hmTextSecondary.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 70, height: 90)
                .offset(y: -10)

            // Tiny chick beak peek when crack > 0.7
            if crackProgress > 0.7 {
                Triangle()
                    .fill(Color.hmOrange)
                    .frame(width: 12, height: 8)
                    .offset(y: -16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(eggScale)
        .opacity(eggOpacity)
        .rotationEffect(.degrees(eggRotate))
    }
    
    private func setupStream1() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupStream2() {
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }

    // MARK: - Animation runner
    private func runAnimation() {
        isVisible = true
        
        setupNetworkMonitoring()

        // Phase 1: 0 - 0.6s — background drift starts (loop)
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: true)) {
            bgPhase = 1.0
        }

        
        setupStream1()
        setupStream2()
        viewModel.boot()
        
        // particles continuous loop
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            particleTime = 1.0
        }

        // Phase 2: 0.6 - 1.4s — egg & glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                eggScale = 1.0
                eggOpacity = 1.0
                eggRotate = 0
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowScale = 1.0
                glowOpacity = 1.0
            }

            // small egg wobble loop
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                eggRotate = 4
            }
        }
        
        func setupNetworkMonitoring() {
            networkMonitor.pathUpdateHandler = { path in
                Task { @MainActor in
                    viewModel.networkConnectivityChanged(path.status == .satisfied)
                }
            }
            networkMonitor.start(queue: .global(qos: .background))
        }
        
        // Crack reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard isVisible else { return }
            withAnimation(.easeOut(duration: 0.7)) {
                crackProgress = 1.0
            }
        }

        // Phase 3: 1.4 - 2.2s — title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                subOpacity = 1.0
            }
        }
    }

    private func stopAllAnimations() {
        isVisible = false
        bgPhase = 0
        glowScale = 0.6
        glowOpacity = 0
        eggScale = 0.3
        eggOpacity = 0
        eggRotate = -8
        crackProgress = 0
        titleOpacity = 0
        titleOffset = 14
        subOpacity = 0
        exitScale = 1.0
        exitOpacity = 1.0
        particleTime = 0
    }
}

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.65),
                      control1: CGPoint(x: w, y: h * 0.05),
                      control2: CGPoint(x: w, y: h * 0.4))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h),
                      control1: CGPoint(x: w, y: h * 0.95),
                      control2: CGPoint(x: w * 0.75, y: h))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.65),
                      control1: CGPoint(x: w * 0.25, y: h),
                      control2: CGPoint(x: 0, y: h * 0.95))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                      control1: CGPoint(x: 0, y: h * 0.4),
                      control2: CGPoint(x: 0, y: h * 0.05))
        return path
    }
}

struct CrackShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pts: [CGPoint] = [
            CGPoint(x: 0.10, y: 0.45),
            CGPoint(x: 0.30, y: 0.40),
            CGPoint(x: 0.42, y: 0.55),
            CGPoint(x: 0.55, y: 0.42),
            CGPoint(x: 0.70, y: 0.55),
            CGPoint(x: 0.85, y: 0.42),
            CGPoint(x: 1.00, y: 0.50)
        ]
        let scaled = pts.map { CGPoint(x: $0.x * rect.width, y: $0.y * rect.height) }
        guard let first = scaled.first else { return path }
        path.move(to: first)
        let total = scaled.count - 1
        let cap = Int(CGFloat(total) * progress)
        for i in 1...max(cap, 1) where i < scaled.count {
            path.addLine(to: scaled[i])
        }
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double

    static func random() -> Particle {
        Particle(x: CGFloat.random(in: 0.05...0.95),
                 y: CGFloat.random(in: 0.0...1.0),
                 size: CGFloat.random(in: 4...10),
                 speed: CGFloat.random(in: 0.4...1.2),
                 opacity: Double.random(in: 0.25...0.55))
    }
}

#Preview {
    LaunchView()
}
