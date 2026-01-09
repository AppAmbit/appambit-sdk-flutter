import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appambit_sdk_push_notifications_method_channel.dart';

abstract class AppambitSdkPushNotificationsPlatform extends PlatformInterface {

  Future<void> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> requestNotificationPermission() {
    throw UnimplementedError('requestNotificationPermission() has not been implemented.');
  }

  Future<void> setNotificationsEnabled(bool enabled) {
    throw UnimplementedError('setNotificationsEnabled() has not been implemented.');
  }

  Future<bool> isNotificationsEnabled() {
    throw UnimplementedError('isNotificationsEnabled() has not been implemented.');
  }
  
}