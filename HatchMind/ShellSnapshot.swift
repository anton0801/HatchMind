import Foundation
import os

struct ShellSnapshot {
    var beacons: [String: String] = [:]
    var crumbs: [String: String] = [:]
    var yolkURL: String? = nil
    var yolkMode: String? = nil
    var unincubated: Bool = true
    var hatched: Bool = false
    var consentTucked: Bool = false
    var consentChilled: Bool = false
    var consentImprintedAt: Date? = nil
    
    var beaconsReady: Bool { !beacons.isEmpty }
    
    var consentRipe: Bool {
        guard !consentTucked && !consentChilled else { return false }
        if let date = consentImprintedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func hydrate(from record: ShellRecord) -> ShellSnapshot {
        var snap = ShellSnapshot()
        snap.beacons = record.beacons
        snap.crumbs = record.crumbs
        snap.yolkURL = record.yolkURL
        snap.yolkMode = record.yolkMode
        snap.unincubated = record.unincubated
        snap.consentTucked = record.consentTucked
        snap.consentChilled = record.consentChilled
        snap.consentImprintedAt = record.consentImprintedAt
        return snap
    }
    
    func freeze() -> ShellRecord {
        ShellRecord(
            beacons: beacons, crumbs: crumbs,
            yolkURL: yolkURL, yolkMode: yolkMode,
            unincubated: unincubated,
            consentTucked: consentTucked,
            consentChilled: consentChilled,
            consentImprintedAt: consentImprintedAt
        )
    }
}

final class ShellVessel {
    
    private var _state: ShellSnapshot
    private var _lock = os_unfair_lock()
    
    init(initial: ShellSnapshot = ShellSnapshot()) {
        self._state = initial
    }
    
    var snapshot: ShellSnapshot {
        os_unfair_lock_lock(&_lock)
        let copy = _state
        os_unfair_lock_unlock(&_lock)
        return copy
    }
    
    func mutate(_ block: (inout ShellSnapshot) -> Void) {
        os_unfair_lock_lock(&_lock)
        block(&_state)
        os_unfair_lock_unlock(&_lock)
    }
    
    func replace(with new: ShellSnapshot) {
        os_unfair_lock_lock(&_lock)
        _state = new
        os_unfair_lock_unlock(&_lock)
    }
    
    func project<R>(_ block: (ShellSnapshot) -> R) -> R {
        os_unfair_lock_lock(&_lock)
        let result = block(_state)
        os_unfair_lock_unlock(&_lock)
        return result
    }
}
