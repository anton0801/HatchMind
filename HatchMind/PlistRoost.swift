import Foundation

protocol ShellRoost {
    func stash(_ record: ShellRecord)
    func stashYolk(url: String, mode: String)
    func markPrimed()
    func thaw() -> ShellRecord
}

final class PlistXMLRoost: ShellRoost {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("HatchShell", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: ShellConstants.suiteShell) ?? .standard
    }
    
    private var plistURL: URL {
        dataDir.appendingPathComponent(ShellConstants.plistFile)
    }
    
    func stash(_ record: ShellRecord) {
        var dict: [String: Any] = [:]
        dict["beacons"] = veilDict(record.beacons)
        dict["crumbs"] = veilDict(record.crumbs)
        if let url = record.yolkURL { dict["yolkURL"] = url }
        if let mode = record.yolkMode { dict["yolkMode"] = mode }
        dict["unincubated"] = record.unincubated
        dict["consentTucked"] = record.consentTucked
        dict["consentChilled"] = record.consentChilled
        if let date = record.consentImprintedAt {
            dict["consentImprintedAt"] = date.timeIntervalSince1970
        }
        
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .xml,
                options: 0
            )
            try plistData.write(to: plistURL, options: .atomic)
        } catch {
            print("\(ShellConstants.logEgg) Stash failed: \(error)")
        }
    }
    
    func stashYolk(url: String, mode: String) {
        suiteStore.set(url, forKey: ShellKey.yolkURL)
        homeStore.set(url, forKey: ShellKey.yolkURL)
        suiteStore.set(mode, forKey: ShellKey.yolkMode)
    }
    
    func markPrimed() {
        suiteStore.set(true, forKey: ShellKey.primed)
        homeStore.set(true, forKey: ShellKey.primed)
    }
    
    // MARK: - Thaw
    
    func thaw() -> ShellRecord {
        guard fm.fileExists(atPath: plistURL.path),
              let data = try? Data(contentsOf: plistURL),
              let dict = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil
              ) as? [String: Any] else {
            return fallback()
        }
        
        let beacons = unveilDict(dict["beacons"] as? [String: String] ?? [:])
        let crumbs = unveilDict(dict["crumbs"] as? [String: String] ?? [:])
        let yolkURL = dict["yolkURL"] as? String
        let yolkMode = dict["yolkMode"] as? String
        let unincubated = dict["unincubated"] as? Bool ?? true
        let consentTucked = dict["consentTucked"] as? Bool ?? false
        let consentChilled = dict["consentChilled"] as? Bool ?? false
        let consentDate = (dict["consentImprintedAt"] as? TimeInterval)
            .map { Date(timeIntervalSince1970: $0) }
        
        return ShellRecord(
            beacons: beacons, crumbs: crumbs,
            yolkURL: yolkURL, yolkMode: yolkMode,
            unincubated: unincubated,
            consentTucked: consentTucked, consentChilled: consentChilled,
            consentImprintedAt: consentDate
        )
    }
    
    private func fallback() -> ShellRecord {
        let yolkURL = homeStore.string(forKey: ShellKey.yolkURL)
            ?? suiteStore.string(forKey: ShellKey.yolkURL)
        let yolkMode = suiteStore.string(forKey: ShellKey.yolkMode)
        let primed = suiteStore.bool(forKey: ShellKey.primed)
        
        return ShellRecord(
            beacons: [:], crumbs: [:],
            yolkURL: yolkURL, yolkMode: yolkMode,
            unincubated: !primed,
            consentTucked: false, consentChilled: false, consentImprintedAt: nil
        )
    }
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = veil(v) }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unveil(v) ?? v }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "<")
            .replacingOccurrences(of: "/", with: ">")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "<", with: "+")
            .replacingOccurrences(of: ">", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}
