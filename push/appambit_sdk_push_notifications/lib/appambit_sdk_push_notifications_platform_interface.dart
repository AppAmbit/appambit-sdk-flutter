import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appambit_sdk_push_notifications_method_channel.dart';

abstract class AppambitSdkPushNotificationsPlatform
    extends PlatformInterface {
  AppambitSdkPushNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppambitSdkPushNotificationsPlatform _instance = MethodChannelAppambitSdkPushNotifications();

  static AppambitSdkPushNotificationsPlatform get instance => _instance;

  static set instance(AppambitSdkPushNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> start();

  Future<void> requestNotificationPermission();

  Future<void> setNotificationsEnabled(bool enabled);

  Future<bool> isNotificationsEnabled();
}
