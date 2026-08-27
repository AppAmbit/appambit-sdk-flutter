import Flutter
import UIKit
import Network
import UserNotifications
import AppAmbit
import AppAmbitPushNotifications

public class AppambitSdkPushNotificationsPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    private var listenerInstalled = false

    // MARK: - Pending sync keys
    private static let kHasPending = "appambit_push_has_pending"
    private static let kPendingEnabled = "appambit_push_pending_enabled"

    private static func savePendingSync(enabled: Bool) {
        let d = UserDefaults.standard
        d.set(true, forKey: kHasPending)
        d.set(enabled, forKey: kPendingEnabled)
    }

    private static func clearPendingSync() {
        let d = UserDefaults.standard
        d.removeObject(forKey: kHasPending)
        d.removeObject(forKey: kPendingEnabled)
    }

    /// Called from `case "start"` — always after AppAmbit is initialized
    /// (Dart calls AppAmbitSdk.start before PushNotificationsSdk.start).
    ///
    /// Root cause: APNs delivers the token fast on physical devices (~50-100 ms).
    /// TokenListenerImpl.sync fires before AppAmbit is ready, retries once at
    /// +0.5 s, then drops the token. When Dart's start() later replaces the
    /// token listener, handleNewToken's `guard token != currentToken` prevents
    /// re-delivery, so ConsumerService is never called for the pending state.
    ///
    /// Fix: at Dart-start time AppAmbit IS ready. Wait for the APNs token to be
    /// in memory, then call setNotificationsEnabled directly — ConsumerService
    /// gets a valid token and the correct enabled state.
    private static func flushPendingSyncIfNeeded() {
        guard UserDefaults.standard.bool(forKey: kHasPending) else { return }
        let enabled = UserDefaults.standard.bool(forKey: kPendingEnabled)
        // Fire-and-forget — never blocks start().
        waitForTokenThenSync(enabled: enabled, attempt: 0)
    }

    private static func waitForTokenThenSync(enabled: Bool, attempt: Int) {
        // Give up after 5 s (10 × 0.5 s). If no token by then the device is
        // likely offline; the flag stays for the next launch.
        guard attempt < 10 else { return }

        let token = PushKernel.getCurrentToken() ?? ""
        guard !token.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                waitForTokenThenSync(enabled: enabled, attempt: attempt + 1)
            }
            return
        }

        // Token is in memory — AppAmbit is already initialized (see caller).
        // Check network before hitting ConsumerService.
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            monitor.cancel()
            guard path.status == .satisfied else { return }
            DispatchQueue.main.async {
                PushNotifications.setNotificationsEnabled(enabled)
                clearPendingSync()
            }
        }
        monitor.start(queue: DispatchQueue(label: "appambit.netcheck"))
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appambit_sdk_push_notifications",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppambitSdkPushNotificationsPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Bootstrap the iOS SDK during `application(_:didFinishLaunchingWithOptions:)`
        // so the UNUserNotificationCenter delegate is installed in time for iOS
        // to deliver a cold-start tap (`didReceive` for `UNNotificationResponse`).
        // We deliberately do NOT install the plugin's notification listener
        // here — that happens later when Dart calls `setOpenedListener`. In the
        // meantime the SDK queues any tap-driven notification internally and
        // replays it once the listener is registered, by which point Dart's
        // `setMethodCallHandler` is also set so the channel message reaches the
        // user's callback. `start()` is idempotent so calling it again from
        // Dart is harmless.
        PushNotifications.start()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            Self.flushPendingSyncIfNeeded()
            PushNotifications.start()
            installNotificationListenerIfNeeded()
            // If the APNs token arrived before AppAmbit was ready (TokenListenerImpl dropped it),
            // sync it now — AppAmbit.start() has completed so consumerId is set.
            let token = PushKernel.getCurrentToken() ?? ""
            if !token.isEmpty {
                ConsumerService.shared.updateConsumer(
                    deviceToken: token,
                    pushEnabled: PushKernel.isNotificationsEnabled()
                )
            }
            result(nil)

        case "setNotificationsEnabled":
            let args = call.arguments as? [String: Any]
            let enabled = args?["enabled"] as? Bool ?? true
            Self.savePendingSync(enabled: enabled)
            // Update in-memory / UserDefaults state immediately so this session is consistent.
            PushKernel.setNotificationsEnabled(enabled)
            // Only write to the DB + hit the backend when online. If offline, the DB stays at
            // its previous value — flushPendingSyncIfNeeded needs that mismatch on the next
            // online launch to bypass ConsumerService deduplication and actually reach the backend.
            let setEnabled = enabled
            let setToken = PushKernel.getCurrentToken()
            let setMonitor = NWPathMonitor()
            setMonitor.pathUpdateHandler = { path in
                setMonitor.cancel()
                guard path.status == .satisfied else { return }
                DispatchQueue.main.async {
                    ConsumerService.shared.updateConsumer(deviceToken: setToken, pushEnabled: setEnabled)
                    Self.clearPendingSync()
                }
            }
            setMonitor.start(queue: DispatchQueue(label: "appambit.setNotif"))
            result(nil)

        case "isNotificationsEnabled":
            result(PushNotifications.isNotificationsEnabled())

        case "requestNotificationPermission":
            PushNotifications.requestNotificationPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        Self.savePendingSync(enabled: true)
                        // PushKernel already called setNotificationsEnabled(true) internally.
                        // Only write to DB + backend when online (same reason as setNotificationsEnabled).
                        let permToken = PushKernel.getCurrentToken()
                        let permMonitor = NWPathMonitor()
                        permMonitor.pathUpdateHandler = { path in
                            permMonitor.cancel()
                            guard path.status == .satisfied else { return }
                            DispatchQueue.main.async {
                                ConsumerService.shared.updateConsumer(deviceToken: permToken, pushEnabled: true)
                                Self.clearPendingSync()
                            }
                        }
                        permMonitor.start(queue: DispatchQueue(label: "appambit.reqPerm"))
                    }
                    result(granted)
                }
            }

        case "hasNotificationPermission":
            result(PushNotifications.hasNotificationPermission())

        case "setForegroundListener", "setOpenedListener":
            installNotificationListenerIfNeeded()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Notification listener

    private func installNotificationListenerIfNeeded() {
        guard !listenerInstalled else { return }
        listenerInstalled = true

        PushNotifications.setNotificationListener { [weak self] (userInfo: [AnyHashable: Any], state: PushNotificationState) in
            guard let self = self, let channel = self.channel else { return }
            let payload = Self.parsePayload(userInfo)
            let method = (state == .foreground) ? "onForegroundNotification" : "onOpenedNotification"
            DispatchQueue.main.async {
                channel.invokeMethod(method, arguments: payload)
            }
        }
    }

    // MARK: - Payload mapping

    /// Converts an APNs `userInfo` dictionary into the Dart `PushNotificationData`
    /// map shape. Top-level custom keys are forwarded in `data`; the standard
    /// `aps` fields are surfaced under `ios`. The raw `aps` dictionary is not
    /// copied into `data`.
    private static func parsePayload(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]

        let title = alert?["title"] as? String
        let body = alert?["body"] as? String
        let imageUrl = userInfo["image"] as? String

        var data: [String: String] = [:]
        for (key, value) in userInfo {
            guard let k = key as? String, k != "aps", k != "image" else { continue }
            data[k] = "\(value)"
        }

        var ios: [String: Any] = [:]
        if let badge = aps?["badge"] as? Int { ios["badge"] = badge }
        if let sound = aps?["sound"] as? String { ios["sound"] = sound }
        if let category = aps?["category"] as? String { ios["category"] = category }
        if let threadId = aps?["thread-id"] as? String { ios["threadId"] = threadId }

        var payload: [String: Any] = [:]
        if let title { payload["title"] = title }
        if let body { payload["body"] = body }
        if let imageUrl { payload["imageUrl"] = imageUrl }
        if !data.isEmpty { payload["data"] = data }
        if !ios.isEmpty { payload["ios"] = ios }
        return payload
    }
}
