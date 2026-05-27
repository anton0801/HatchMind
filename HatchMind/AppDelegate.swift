import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AdjustSdk
import AdSupport

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let firebaseSub = FirebaseSubdelegate()
    private let messagingSub = MessagingSubdelegate()
    private let notificationsSub = NotificationsSubdelegate()
    private let attributionSub = AttributionSubdelegate()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        firebaseSub.setUp()
        messagingSub.setUp()
        notificationsSub.setUp()
        attributionSub.setUp()
        
        notificationsSub.onPushPayload = { [weak self] payload in
            self?.attributionSub.processPushPayload(payload)
        }
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            attributionSub.processPushPayload(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        messagingSub.setApnsToken(deviceToken)
        Adjust.setPushToken(deviceToken)
    }
    
    @objc private func onActivation() {
        attributionSub.activateAttribution()
    }
}

final class FirebaseSubdelegate {
    func setUp() {
        FirebaseApp.configure()
    }
}

final class MessagingSubdelegate: NSObject, MessagingDelegate {
    
    func setUp() {
        Messaging.messaging().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func setApnsToken(_ token: Data) {
        Messaging.messaging().apnsToken = token
    }
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: ShellKey.fcm)
            UserDefaults.standard.set(t, forKey: ShellKey.push)
            UserDefaults(suiteName: ShellConstants.suiteShell)?.set(t, forKey: "shared_fcm")
        }
    }
}

final class NotificationsSubdelegate: NSObject, UNUserNotificationCenterDelegate {
    
    var onPushPayload: (([AnyHashable: Any]) -> Void)?
    
    func setUp() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        onPushPayload?(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        onPushPayload?(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        onPushPayload?(userInfo)
        completionHandler(.newData)
    }
}

final class AttributionSubdelegate: NSObject, AdjustDelegate {
    
    private var beaconsBuffer: [AnyHashable: Any] = [:]
    private var crumbsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    private static var trackingStarted = false
    
    func setUp() {
    }
    
    func activateAttribution() {
        guard !AttributionSubdelegate.trackingStarted else { return }
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    guard !AttributionSubdelegate.trackingStarted else { return }
                    AttributionSubdelegate.trackingStarted = true
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    self?.initAdjust()
                    NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    UserDefaults.standard.set(idfa, forKey: "idfa_user")
                }
            }
        } else {
            AttributionSubdelegate.trackingStarted = true
            initAdjust()
            NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
        }
    }
    
    func getIDFV() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unavailable"
    }
    
    private func initAdjust() {
        guard let config = ADJConfig(
            appToken: ShellConstants.adjustAppToken,
            environment: ADJEnvironmentProduction
        ) else {
            return
        }
        config.delegate = self
        config.logLevel = ADJLogLevel.suppress
        Adjust.initSdk(config)
        Adjust.idfv { adIdfv in
            let idfv = adIdfv ?? self.getIDFV()
            UserDefaults.standard.set(idfv, forKey: "idfv_user")
        }
    }
    
    func processPushPayload(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: ShellKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        
        var data: [AnyHashable: Any] = [:]
        if let network      = attribution.network      { data["network"]       = network }
        if let campaign     = attribution.campaign     { data["campaign"]      = campaign }
        if let adgroup      = attribution.adgroup      { data["adgroup"]       = adgroup }
        if let creative     = attribution.creative     { data["creative"]      = creative }
        if let clickLabel   = attribution.clickLabel   { data["click_label"]   = clickLabel }
        if let trackerName  = attribution.trackerName  { data["tracker_name"]  = trackerName }
        if let trackerToken = attribution.trackerToken { data["tracker_token"] = trackerToken }
        if let costType     = attribution.costType     { data["cost_type"]     = costType }
        if let costAmount   = attribution.costAmount   { data["cost_amount"]   = costAmount }
        if let costCurrency = attribution.costCurrency { data["cost_currency"] = costCurrency }
        data["is_organic"] = attribution.network == nil || attribution.network == "Organic"
        
        beaconsBuffer = data
        scheduleFuse()
        if !crumbsBuffer.isEmpty { performFuse() }
        
        NotificationCenter.default.post(name: .init("AdjustAttributionReceived"), object: nil)
    }
    
    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        let desc = sessionFailureResponseData?.message ?? "unknown"
        beaconsBuffer = ["error": true, "error_desc": desc]
        scheduleFuse()
    }
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        guard let deeplink else { return false }
        guard !UserDefaults.standard.bool(forKey: ShellKey.primed) else { return true }
        
        let data: [AnyHashable: Any] = [
            "deeplink_url":    deeplink.absoluteString,
            "deeplink_scheme": deeplink.scheme ?? "",
            "deeplink_host":   deeplink.host ?? "",
            "deeplink_path":   deeplink.path
        ]
        
        crumbsBuffer = data
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseTimer?.invalidate()
        if !beaconsBuffer.isEmpty { performFuse() }
        return true
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = beaconsBuffer
        for (k, v) in crumbsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": combined]
        )
    }
}
