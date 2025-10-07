import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'appambit_sdk_flutter_method_channel.dart' as _impl;
import 'appambit_sdk_flutter_platform_interface.dart';

class AppambitSdk {
  static bool _hooksInstalled = false;
  static RawReceivePort? _isolateErrorPort;

  static void _ensureRegistered() {
    _impl.registerMethodChannelImplementation();
  }

  /// Starts the core SDK with the provided app key.
  static Future<void> start({ required String appKey }) async {
    _ensureRegistered();
    await AppAmbitSdkFlutterPlatform.instance.startCore(appKey: appKey);
    _installGlobalErrorHooks();
  }

  /// Sets the current user identifier for analytics correlation.
  static Future<void> setUserId(String userId) {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.setUserId(userId);
  }

  /// Sets the current user email for analytics correlation.
  static Future<void> setEmail(String email) {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.setEmail(email);
  }

  /// Clears the current auth token (forces a refresh on next request if applicable).
  static Future<void> clearToken() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.clearToken();
  }

  /// Starts a manual analytics session (when manual sessions are enabled).
  static Future<void> startSession() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.startSession();
  }

  /// Ends the current manual analytics session (when manual sessions are enabled).
  static Future<void> endSession() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.endSession();
  }

  /// Enables manual session control mode.
  static Future<void> enableManualSession() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.enableManualSession();
  }

  /// Tracks a custom event with string-to-string properties.
  static Future<void> trackEvent(String name, Map<String, String> properties) {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.trackEvent(name, properties);
  }

  /// Generates a small test event to validate ingestion.
  static Future<void> generateTestEvent() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.generateTestEvent();
  }

  /// Returns whether the app crashed in the previous session.
  static Future<bool> didCrashInLastSession() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.didCrashInLastSession();
  }

  /// Triggers a native crash for testing (use in debug only).
  static Future<void> generateTestCrash() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.generateTestCrash();
  }

  /// Unified error logger.
  ///
  /// Use ONE API for both use cases:
  /// - Message-only:     logError(message: "Human readable message")
  /// - Exception/stack:  logError(exception: e, stackTrace: st, properties: {...}, classFqn: ..., fileName: ..., lineNumber: ...)
  ///
  /// The SDK stringifies `exception` and normalizes `stackTrace` internally.
  static Future<void> logError({
    String? message,
    Object? exception,
    StackTrace? stackTrace,
    Map<String, String>? properties,
    String? classFqn,
    String? fileName,
    int? lineNumber,
  }) {
    _ensureRegistered();

    final String? messageStr = (message != null && message.isNotEmpty)
        ? message
        : _stringify(exception);

    final String? stackStr = _normalizeStackTrace(exception, stackTrace);

    final Map<String, dynamic> payload = {};

    if (messageStr != null && messageStr.isNotEmpty) {
      payload['message'] = messageStr;
    }
    if (stackStr != null && stackStr.isNotEmpty) {
      payload['stackTrace'] = stackStr;
    }
    if (properties != null && properties.isNotEmpty) {
      payload['properties'] = properties;
    }
    if (classFqn != null && classFqn.isNotEmpty) {
      payload['classFqn'] = classFqn;
    }
    if (fileName != null && fileName.isNotEmpty) {
      payload['fileName'] = fileName;
    }
    if (lineNumber != null) {
      payload['lineNumber'] = lineNumber;
    }

    if (payload.isEmpty) return Future.value();

    return AppAmbitSdkFlutterPlatform.instance.logError(payload);
  }

  /// Best-effort conversion to human-friendly string.
  static String? _stringify(Object? value) {
    if (value == null) return null;
    try {
      return value.toString();
    } catch (_) {
      return '(${value.runtimeType})';
    }
  }

  /// Prefer the explicit param; otherwise pull from `Error.stackTrace` when available.
  static String? _normalizeStackTrace(Object? exception, StackTrace? stackTrace) {
    final StackTrace? st = stackTrace ?? (exception is Error ? exception.stackTrace : null);
    return st?.toString();
  }

  static void _installGlobalErrorHooks() {
    if (_hooksInstalled) return;
    _hooksInstalled = true;

    final originalFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final Object error = details.exception;
      final StackTrace stack = details.stack ?? StackTrace.current;
      AppambitSdk.logError(exception: error, stackTrace: stack);
      try { originalFlutterOnError?.call(details); } catch (_) {}
      try { FlutterError.presentError(details); } catch (_) {}
    };

    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppambitSdk.logError(exception: error, stackTrace: stack);
      return true;
    };

    _isolateErrorPort = RawReceivePort((dynamic pair) {
      final List<dynamic> errorAndStack = pair as List<dynamic>;
      final Object error = errorAndStack.first;
      final StackTrace stack = StackTrace.fromString(errorAndStack.last as String);
      AppambitSdk.logError(exception: error, stackTrace: stack);
    });
    Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);
  }
}
