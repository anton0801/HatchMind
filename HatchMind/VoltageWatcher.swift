import Foundation
import Combine
import AdjustSdk
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

protocol VoltageWatcher {
    func watchVoltage() async throws -> Bool
}

protocol YolkFinder {
    func find(seed: [String: Any]) async throws -> String
}

protocol ConsentEmitter {
    func emit() -> AnyPublisher<Bool, Never>
    func armPushBeacon()
}

final class HTTPYolkFinder: YolkFinder {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw HatchFault.wireSnapped
        }
        
        if http.statusCode == 404 {
            throw HatchFault.nestSealed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HatchFault.malformedCrack
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw HatchFault.malformedCrack
        }
        
        if !ok {
            throw HatchFault.incubatorRejected
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw HatchFault.malformedCrack
        }
        
        return url
    }
    
    func find(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: ShellConstants.backendNursery) else {
            throw HatchFault.malformedCrack
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        // Adjust device ID вместо AppsFlyer UID
        body["adjust_id"] = await Adjust.adid() ?? ""
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["idfa"] = UserDefaults.standard.string(forKey: "idfa_user") ?? ""
        body["store_id"] = "id\(ShellConstants.appCode)"
        body["idfv"] = UserDefaults.standard.string(forKey: "idfv_user") ?? ""
        body["push_token"] = UserDefaults.standard.string(forKey: ShellKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastFault: Error?
        
        for (idx, pause) in pauseStops.enumerated() {
            do {
                return try await singleShot(request)
            } catch let fault as HatchFault {
                if fault.category == "denial" && fault != .voltageStaled { throw fault }
                if fault == .feedClogged {
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                    continue
                }
                lastFault = fault
                if idx < pauseStops.count - 1 && fault.retryable {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            } catch {
                lastFault = error
                if idx < pauseStops.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        if let lastFault = lastFault { throw lastFault }
        throw HatchFault.wireSnapped
    }
    
    private let pauseStops: [Double] = [90.0, 180.0, 360.0]
    
}

final class SupabaseVoltageWatcher: VoltageWatcher {
    
    func watchVoltage() async throws -> Bool {
        return true
    }
}
