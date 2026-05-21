import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appambit_sdk_push_notifications_method_channel.dart';
import 'src/push_notification_data.dart';

typedef PushNotificationListener = void Function(PushNotificationData data);
typedef PermissionResultCallback = void Function(bool granted);

abstract class AppambitSdkPushNotificationsPlatform extends PlatformInterface {
  AppambitSdkPushNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppambitSdkPushNotificationsPlatform _instance =
      MethodChannelAppambitSdkPushNotifications();

  static AppambitSdkPushNotificationsPlatform get instance => _instance;

  static set instance(AppambitSdkPushNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> requestNotificationPermission({
    PermissionResultCallback? callback,
  }) {
    throw UnimplementedError(
      'requestNotificationPermission() has not been implemented.',
    );
  }

  Future<bool> hasSystemPermission() {
    throw UnimplementedError(
      'hasSystemPermission() has not been implemented.',
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) {
    throw UnimplementedError(
      'setNotificationsEnabled() has not been implemented.',
    );
  }

  Future<bool> isNotificationsEnabled() {
    throw UnimplementedError(
      'isNotificationsEnabled() has not been implemented.',
    );
  }

  void setForegroundListener(PushNotificationListener listener) {
    throw UnimplementedError(
      'setForegroundListener() has not been implemented.',
    );
  }

  void setOpenedListener(PushNotificationListener listener) {
    throw UnimplementedError('setOpenedListener() has not been implemented.');
  }

  Future<void> setBackgroundHandler(PushNotificationListener listener) {
    throw UnimplementedError(
      'setBackgroundHandler() has not been implemented.',
    );
  }
}
