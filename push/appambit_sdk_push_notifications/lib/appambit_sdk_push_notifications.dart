import 'appambit_sdk_push_notifications_platform_interface.dart';

class PushNotificationsSdk {
  static Future<void> start() {
    return AppambitSdkPushNotificationsPlatform.instance.start();
  }

  static Future<void> requestNotificationPermission() {
    return AppambitSdkPushNotificationsPlatform.instance
        .requestNotificationPermission();
  }

  static Future<void> setNotificationsEnabled(bool enabled) {
    return AppambitSdkPushNotificationsPlatform.instance
        .setNotificationsEnabled(enabled);
  }

  static Future<bool> isNotificationsEnabled() {
    return AppambitSdkPushNotificationsPlatform.instance
        .isNotificationsEnabled();
  }
}