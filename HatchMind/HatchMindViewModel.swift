import Foundation
import Combine

@MainActor
final class HatchMindViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                cachedDataTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                cachedDataTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let driver: ContinuationDriver
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    private var cachedDataTask: Task<Void, Never>?
    private var attObserver: NSObjectProtocol?
    
    private var uiLocked = false
    private var adjustAttributionReceived = false
    
    init() {
        self.driver = ContinuationDriver()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
        cachedDataTask?.cancel()
        if let obs = attObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    private func wireUp() {
        driver.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        driver.warmUp()
        armDeadline()
        
        attObserver = NotificationCenter.default.addObserver(
            forName: .init("ATTConsentDone"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.uiLocked else { return }
            self.armCachedDataFallback()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        adjustAttributionReceived = true
        cachedDataTask?.cancel()
        cachedDataTask = nil
        
        Task {
            driver.ingestBeacons(data)
            await driver.incubate()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        driver.ingestCrumbs(data)
    }
    
    func acceptConsent() {
        driver.acceptConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        driver.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: HatchOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .incubating:       break
        case .requestConsent:   showPermissionPrompt = true
        case .openYolk:         navigateToWeb = true
        case .nestedInRoost:    navigateToMain = true
        }
    }
    
    // MARK: - Cached Data Fallback
    
    private func armCachedDataFallback() {
        guard !adjustAttributionReceived else {
            return
        }
        
        let beaconsReady = driver.vessel.project { $0.beaconsReady }
        guard beaconsReady else {
            return
        }
        
        cachedDataTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            guard let self else { return }
            guard !Task.isCancelled else { return }
            guard !self.uiLocked else { return }
            guard !self.adjustAttributionReceived else { return }
            
            let cached = self.driver.vessel.project { $0.beacons }
            
            NotificationCenter.default.post(
                name: .init("ConversionDataReceived"),
                object: nil,
                userInfo: ["conversionData": cached]
            )
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self else { return }
            let shouldFire = self.driver.reportHeatLost()
            if shouldFire { self.handleOutcome(.nestedInRoost) }
        }
    }
}
