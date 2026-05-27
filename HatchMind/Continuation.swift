import Foundation
import Combine
import AdjustSdk

enum Continuation {
    case next(StepFunction)
    case terminate(HatchOutcome)
    case fail(HatchFault)
}

typealias StepFunction = (ShellVessel) async -> Continuation

@MainActor
enum HatchSteps {
    
    static func pushCheck() -> StepFunction {
        return { vessel in
            guard let pushURL = UserDefaults.standard.string(forKey: ShellKey.pushURL),
                  !pushURL.isEmpty else {
                return .next(voltageCheck())
            }
            
            let needsConsent = vessel.project { $0.consentRipe }
            
            vessel.mutate { snap in
                snap.yolkURL = pushURL
                snap.yolkMode = "Active"
                snap.unincubated = false
                snap.hatched = true
            }
            
            let snapshot = vessel.project { $0.freeze() }
            let roost = HatchFactory.roost()
            roost.stash(snapshot)
            roost.stashYolk(url: pushURL, mode: "Active")
            roost.markPrimed()
            UserDefaults.standard.removeObject(forKey: ShellKey.pushURL)
            
            return .terminate(needsConsent ? .requestConsent : .openYolk)
        }
    }
    
    static func voltageCheck() -> StepFunction {
        return { vessel in
            let ready = vessel.project { $0.beaconsReady }
            guard ready else {
                return .terminate(.incubating)
            }
            
            do {
                let verdict = try await HatchFactory.voltageWatcher().watchVoltage()
                if verdict {
                    return .next(yolkSearch())
                } else {
                    return .fail(.voltageStaled)
                }
            } catch let fault as HatchFault {
                return .fail(fault)
            } catch {
                return .fail(.voltageStaled)
            }
        }
    }
    
    static func yolkSearch() -> StepFunction {
        return { vessel in
            let ready = vessel.project { $0.beaconsReady }
            guard ready else {
                return .terminate(.incubating)
            }
            
            let beacons = vessel.project { $0.beacons }
            let seed = beacons.mapValues { $0 as Any }
            
            do {
                let url = try await HatchFactory.yolkFinder().find(seed: seed)
                
                let needsConsent = vessel.project { $0.consentRipe }
                
                vessel.mutate { snap in
                    snap.yolkURL = url
                    snap.yolkMode = "Active"
                    snap.unincubated = false
                    snap.hatched = true
                }
                
                let snapshot = vessel.project { $0.freeze() }
                let roost = HatchFactory.roost()
                roost.stash(snapshot)
                roost.stashYolk(url: url, mode: "Active")
                roost.markPrimed()
                UserDefaults.standard.removeObject(forKey: ShellKey.pushURL)
                
                return .terminate(needsConsent ? .requestConsent : .openYolk)
            } catch let fault as HatchFault {
                return .fail(fault)
            } catch {
                return .fail(.wireSnapped)
            }
        }
    }
}

@MainActor
final class ContinuationDriver {
    
    let vessel: ShellVessel
    
    private let outcomeSubject = PassthroughSubject<HatchOutcome, Never>()
    var outcomePublisher: AnyPublisher<HatchOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    private var consentCancellable: AnyCancellable?
    
    init() {
        self.vessel = ShellVessel()
    }
    
    func warmUp() {
        let record = HatchFactory.roost().thaw()
        vessel.replace(with: ShellSnapshot.hydrate(from: record))
    }
    
    func ingestBeacons(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        vessel.mutate { $0.beacons = mapped }
        let snapshot = vessel.project { $0.freeze() }
        HatchFactory.roost().stash(snapshot)
    }
    
    func ingestCrumbs(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        vessel.mutate { $0.crumbs = mapped }
        let snapshot = vessel.project { $0.freeze() }
        HatchFactory.roost().stash(snapshot)
    }
    
    func incubate() async {
        guard !sequenceCompleted else { return }
        
        var currentStep: StepFunction? = HatchSteps.pushCheck()
        var hops = 0
        let maxHops = 16
        
        while let step = currentStep, hops < maxHops {
            hops += 1
            if sequenceCompleted { return }
            
            let continuation = await step(vessel)
            
            switch continuation {
            case .next(let nextStep):
                currentStep = nextStep
                
            case .terminate(let outcome):
                if case .incubating = outcome {
                    return
                }
                sequenceCompleted = true
                outcomeSubject.send(outcome)
                return
                
            case .fail(let fault):
                sequenceCompleted = true
                outcomeSubject.send(.nestedInRoost)
                return
            }
        }
        
        if hops >= maxHops {
            sequenceCompleted = true
            outcomeSubject.send(.nestedInRoost)
        }
    }
    
    func acceptConsent(after: @escaping () -> Void) {
        let priorTucked = vessel.project { $0.consentTucked }
        let priorChilled = vessel.project { $0.consentChilled }
        
        consentCancellable = HatchFactory.consentEmitter()
            .emit()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let self = self else { return }
                
                let now = Date()
                self.vessel.mutate { snap in
                    if granted {
                        snap.consentTucked = true
                        snap.consentChilled = false
                        snap.consentImprintedAt = now
                    } else {
                        snap.consentTucked = false
                        snap.consentChilled = true
                        snap.consentImprintedAt = now
                    }
                }
                
                if granted { HatchFactory.consentEmitter().armPushBeacon() }
                
                _ = priorTucked; _ = priorChilled
                
                let snapshot = self.vessel.project { $0.freeze() }
                HatchFactory.roost().stash(snapshot)
                self.outcomeSubject.send(.openYolk)
                self.consentCancellable = nil
                after()
            }
    }
    
    func deferConsent() {
        let now = Date()
        vessel.mutate { $0.consentImprintedAt = now }
        let snapshot = vessel.project { $0.freeze() }
        HatchFactory.roost().stash(snapshot)
        outcomeSubject.send(.openYolk)
    }
    
    func reportHeatLost() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}
