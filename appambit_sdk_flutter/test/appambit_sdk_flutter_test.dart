import 'package:flutter_test/flutter_test.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter_platform_interface.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppambitSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements AppambitSdkFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AppambitSdkFlutterPlatform initialPlatform = AppambitSdkFlutterPlatform.instance;

  test('$MethodChannelAppambitSdkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppambitSdkFlutter>());
  });

  test('getPlatformVersion', () async {
    AppambitSdkFlutter appambitSdkFlutterPlugin = AppambitSdkFlutter();
    MockAppambitSdkFlutterPlatform fakePlatform = MockAppambitSdkFlutterPlatform();
    AppambitSdkFlutterPlatform.instance = fakePlatform;

    expect(await appambitSdkFlutterPlugin.getPlatformVersion(), '42');
  });
}
