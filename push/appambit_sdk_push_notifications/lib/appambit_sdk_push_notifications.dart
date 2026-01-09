import 'appambit_sdk_push_notifications_platform_interface.dart';
import 'appambit_sdk_push_notifications_method_channel.dart' as _impl;

class AppambitSdkPushNotifications {

  static void _ensureRegistered() {
    _impl.registerMethodChannelImplementation();
  }

  static Future<void> start() {
    _ensureRegistered();
    return AppambitSdkPushNotificationsPlatform.instance.start();
  }

  static Future<void> requestNotificationPermission() {
    _ensureRegistered();
    return AppambitSdkPushNotificationsPlatform.instance.requestNotificationPermission();
  }

  static Future<void> setNotificationsEnabled(bool enabled) {
    _ensureRegistered();
    return AppambitSdkPushNotificationsPlatform.instance.setNotificationsEnabled(enabled);
  }

  static Future<bool> isNotificationsEnabled() {
    _ensureRegistered();
    return AppambitSdkPushNotificationsPlatform.instance.isNotificationsEnabled();
  }

}