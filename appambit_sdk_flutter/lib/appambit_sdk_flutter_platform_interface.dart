import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AppAmbitSdkFlutterPlatform extends PlatformInterface {
  AppAmbitSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppAmbitSdkFlutterPlatform _instance = throw UnimplementedError(
      'No platform implementation found. Set AppAmbitSdkFlutterPlatform.instance in the platform-specific code.'
  );

  static AppAmbitSdkFlutterPlatform get instance => _instance;

  static set instance(AppAmbitSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startCore({ required String appKey }) {
    throw UnimplementedError('startCore() not implemented');
  }

  Future<void> setUserId(String userId) {
    throw UnimplementedError('setUserId() not implemented');
  }
  Future<void> setEmail(String email) {
    throw UnimplementedError('setEmail() not implemented');
  }
  Future<void> clearToken() {
    throw UnimplementedError('clearToken() not implemented');
  }
  Future<void> startSession() {
    throw UnimplementedError('startSession() not implemented');
  }
  Future<void> endSession() {
    throw UnimplementedError('endSession() not implemented');
  }
  Future<void> enableManualSession() {
    throw UnimplementedError('enableManualSession() not implemented');
  }
  Future<void> trackEvent(String name, Map<String,String> properties) {
    throw UnimplementedError('trackEvent() not implemented');
  }
  Future<void> generateTestEvent() {
    throw UnimplementedError('generateTestEvent() not implemented');
  }

  Future<bool> didCrashInLastSession() {
    throw UnimplementedError('didCrashInLastSession() not implemented');
  }
  Future<void> generateTestCrash() {
    throw UnimplementedError('generateTestCrash() not implemented');
  }
  Future<void> logError(Map<String, dynamic>? payload) {
    throw UnimplementedError('logError() not implemented');
  }
  Future<void> logErrorMessage(
      String message, {
        Map<String,String>? properties,
        String? classFqn,
        String? fileName,
        int? lineNumber,
      }) {
    throw UnimplementedError('logErrorMessage() not implemented');
  }
}
