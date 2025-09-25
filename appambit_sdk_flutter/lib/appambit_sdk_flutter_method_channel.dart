import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appambit_sdk_flutter_platform_interface.dart';

/// An implementation of [AppambitSdkFlutterPlatform] that uses method channels.
class MethodChannelAppambitSdkFlutter extends AppambitSdkFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appambit_sdk_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
