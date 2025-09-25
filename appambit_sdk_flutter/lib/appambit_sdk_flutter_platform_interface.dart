import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appambit_sdk_flutter_method_channel.dart';

abstract class AppambitSdkFlutterPlatform extends PlatformInterface {
  /// Constructs a AppambitSdkFlutterPlatform.
  AppambitSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppambitSdkFlutterPlatform _instance = MethodChannelAppambitSdkFlutter();

  /// The default instance of [AppambitSdkFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppambitSdkFlutter].
  static AppambitSdkFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppambitSdkFlutterPlatform] when
  /// they register themselves.
  static set instance(AppambitSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
