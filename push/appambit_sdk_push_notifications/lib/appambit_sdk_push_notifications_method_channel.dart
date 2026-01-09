import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appambit_sdk_push_notifications_platform_interface.dart';

class MethodChannelAppambitSdkPushNotifications extends AppambitSdkPushNotificationsPlatform {

  @visibleForTesting
  final methodChannel = const MethodChannel('appambit_sdk_push_notifications');

  @override
  Future<void> start() async {
    await methodChannel.invokeMethod('start');
  }

  @override
  Future<void> requestNotificationPermission() async {
    await methodChannel.invokeMethod('requestNotificationPermission');
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await methodChannel.invokeMethod('setNotificationsEnabled', {'enabled': enabled});
  }

  @override
  Future<bool> isNotificationsEnabled() async {
    final bool enabled = await methodChannel.invokeMethod('isNotificationsEnabled');
    return enabled;
  }

}
