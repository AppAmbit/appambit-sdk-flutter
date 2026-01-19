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

  @override
  Future<bool> requestNotificationPermissionWithResult() async {
    final bool? isGranted = await methodChannel.invokeMethod<bool>('requestNotificationPermissionWithResult');
    return isGranted ?? false;
  }

  Function(Map<String, dynamic> data)? _customizerCallback;

  @override
  void setNotificationCustomizer(Function(Map<String, dynamic> data) callback) {
    _customizerCallback = callback;
    methodChannel.invokeMethod('setNotificationCustomizer');
    methodChannel.setMethodCallHandler((call) async {
       if (call.method == "onNotificationReceived") {
         final data = Map<String, dynamic>.from(call.arguments);
         _customizerCallback?.call(data);
       }
    });
  }
}
