import 'package:flutter_test/flutter_test.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications_platform_interface.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppambitSdkPushNotificationsPlatform
    with MockPlatformInterfaceMixin
    implements AppambitSdkPushNotificationsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AppambitSdkPushNotificationsPlatform initialPlatform = AppambitSdkPushNotificationsPlatform.instance;

  test('$MethodChannelAppambitSdkPushNotifications is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppambitSdkPushNotifications>());
  });

  test('getPlatformVersion', () async {
    AppambitSdkPushNotifications appambitSdkPushNotificationsPlugin = AppambitSdkPushNotifications();
    MockAppambitSdkPushNotificationsPlatform fakePlatform = MockAppambitSdkPushNotificationsPlatform();
    AppambitSdkPushNotificationsPlatform.instance = fakePlatform;

    expect(await appambitSdkPushNotificationsPlugin.getPlatformVersion(), '42');
  });
}
