import Foundation
import Combine

enum HatchFactory {
    
    private static var _roost: ShellRoost?
    private static var _watcher: VoltageWatcher?
    private static var _finder: YolkFinder?
    private static var _emitter: ConsentEmitter?
    
    static func roost() -> ShellRoost {
        if let cached = _roost { return cached }
        let new = PlistXMLRoost(); _roost = new; return new
    }
    
    static func voltageWatcher() -> VoltageWatcher {
        if let cached = _watcher { return cached }
        let new = SupabaseVoltageWatcher(); _watcher = new; return new
    }
    
    static func yolkFinder() -> YolkFinder {
        if let cached = _finder { return cached }
        let new = HTTPYolkFinder(); _finder = new; return new
    }
    
    static func consentEmitter() -> ConsentEmitter {
        if let cached = _emitter { return cached }
        let new = NotificationConsentEmitter(); _emitter = new; return new
    }
    
    static func reset() {
        _roost = nil; _watcher = nil; _finder = nil; _emitter = nil
    }
}
