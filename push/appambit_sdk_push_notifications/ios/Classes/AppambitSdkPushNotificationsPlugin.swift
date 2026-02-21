import Flutter
import UIKit
import AppAmbit
import AppAmbitPushNotifications

public class AppambitSdkPushNotificationsPlugin: NSObject, FlutterPlugin {
    
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "appambit_sdk_push_notifications", binaryMessenger: registrar.messenger())
        let instance = AppambitSdkPushNotificationsPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            PushNotifications.start()
            result(nil)
            
        case "setNotificationsEnabled":
            let args = call.arguments as? [String: Any]
            let enabled = args?["enabled"] as? Bool ?? true
            PushNotifications.setNotificationsEnabled(enabled)
            result(nil)
            
        case "isNotificationsEnabled":
            let isEnabled = PushNotifications.isNotificationsEnabled()
            result(isEnabled)
            
        case "requestNotificationPermission":
            PushNotifications.requestNotificationPermission { _ in
                // Flutter's `requestNotificationPermission` without result returns void.
                result(nil)
            }
            
        case "requestNotificationPermissionWithResult":
            PushNotifications.requestNotificationPermission { granted in
                result(granted)
            }
            
        case "setNotificationCustomizer":
            PushNotifications.setNotificationCustomizer { notification in
                // Prepare the payload mapping similar to Android
                var payload = [String: Any]()
                var dataMap = [String: Any]()
                
                // Content mapped to dictionary (e.g userInfo for custom payload items)
                let userInfo = notification.request.content.userInfo
                for (key, value) in userInfo {
                    if let stringKey = key as? String {
                        dataMap[stringKey] = value
                    }
                }
                
                var notificationMap = [String: Any]()
                notificationMap["title"] = notification.request.content.title
                notificationMap["body"] = notification.request.content.body
                
                payload["data"] = dataMap
                payload["notification"] = notificationMap
                
                // Send back to Flutter on the main thread
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onNotificationReceived", arguments: payload)
                }
            }
            result(nil)

            result(nil)

        case "hasNotificationPermission":
            let hasPermission = PushNotifications.hasNotificationPermission()
            result(hasPermission)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
