import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appambit_sdk_flutter_platform_interface.dart';

class MethodChannelAppambitSdkFlutter extends AppAmbitSdkFlutterPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('appambit_sdk_flutter');

  final MethodChannel _core = const MethodChannel('com.appambit/appambitcore');
  final MethodChannel _analytics = const MethodChannel('com.appambit/analytics');
  final MethodChannel _crashes = const MethodChannel('com.appambit/crashes');

  MethodChannelAppambitSdkFlutter._internal() : super() {
    AppAmbitSdkFlutterPlatform.instance = this;
  }

  static MethodChannelAppambitSdkFlutter createAndRegister() {
    return MethodChannelAppambitSdkFlutter._internal();
  }

  // Core
  @override
  Future<void> startCore({ required String appKey }) async {
    await _core.invokeMethod('start', {'appKey': appKey});
  }

  // Breadcrumbs
  @override
  Future<void> addBreadcrumb(String name) {
    return _core.invokeMethod<void>('addBreadcrumb', {'name': name});
  }

  // Analytics
  @override
  Future<void> setUserId(String userId) async {
    await _analytics.invokeMethod('setUserId', {'userId': userId});
  }

  @override
  Future<void> setEmail(String email) async {
    await _analytics.invokeMethod('setEmail', {'email': email});
  }

  @override
  Future<void> clearToken() async {
    await _analytics.invokeMethod('clearToken');
  }

  @override
  Future<void> startSession() async {
    await _analytics.invokeMethod('startSession');
  }

  @override
  Future<void> endSession() async {
    await _analytics.invokeMethod('endSession');
  }

  @override
  Future<void> enableManualSession() async {
    await _analytics.invokeMethod('enableManualSession');
  }

  @override
  Future<void> trackEvent(String name, Map<String,String> properties) async {
    await _analytics.invokeMethod('trackEvent', {'name': name, 'properties': properties});
  }

  @override
  Future<void> generateTestEvent() async {
    await _analytics.invokeMethod('generateTestEvent');
  }

  // Crashes
  @override
  Future<bool> didCrashInLastSession() async {
    final res = await _crashes.invokeMethod<bool>('didCrashInLastSession');
    return res ?? false;
  }

  @override
  Future<void> generateTestCrash() async {
    await _crashes.invokeMethod('generateTestCrash');
  }

  @override
  Future<void> logError(Map<String, dynamic>? payload) async {
    await _crashes.invokeMethod('logError', payload);
  }

  @override
  @override
  Future<void> logErrorMessage(Map<String, dynamic> payload) {
    return _crashes.invokeMethod<void>('logErrorMessage', payload);
  }
}

void registerMethodChannelImplementation() {
  try {
    final _ = AppAmbitSdkFlutterPlatform.instance;
    return;
  } on UnimplementedError {
  }

  MethodChannelAppambitSdkFlutter.createAndRegister();
}
