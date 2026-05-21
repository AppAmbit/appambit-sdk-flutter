import Flutter
import UIKit
import UserNotifications
import AppAmbit
import AppAmbitPushNotifications

public class AppambitSdkPushNotificationsPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    private var listenerInstalled = false

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
            PushNotifications.start()
            installNotificationListenerIfNeeded()
            result(nil)

        case "setNotificationsEnabled":
            let args = call.arguments as? [String: Any]
            let enabled = args?["enabled"] as? Bool ?? true
            PushNotifications.setNotificationsEnabled(enabled)
            result(nil)

        case "isNotificationsEnabled":
            result(PushNotifications.isNotificationsEnabled())

        case "requestNotificationPermission":
            PushNotifications.requestNotificationPermission { granted in
                DispatchQueue.main.async { result(granted) }
            }

        case "hasSystemPermission":
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
    /// map shape. Mirrors `AppAmbitNotification.from(userInfo:)` from the iOS SDK.
    private static func parsePayload(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]

        let title = alert?["title"] as? String
        let subtitle = alert?["subtitle"] as? String
        let body = alert?["body"] as? String
        let imageUrl = userInfo["image"] as? String

        var data: [String: String] = [:]
        for (key, value) in userInfo {
            guard let k = key as? String, k != "aps", k != "image" else { continue }
            data[k] = "\(value)"
        }

        var payload: [String: Any] = [:]
        if let title { payload["title"] = title }
        if let body { payload["body"] = body }
        if let imageUrl { payload["imageUrl"] = imageUrl }
        if !data.isEmpty { payload["data"] = data }
        if let subtitle { payload["ios"] = ["subtitle": subtitle] }
        return payload
    }
}
