import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'appambit_sdk_flutter_method_channel.dart' as _impl;
import 'appambit_sdk_flutter_platform_interface.dart';

class AppambitSdk {
  static bool _hooksInstalled = false;
  static RawReceivePort? _isolateErrorPort;

  static final Map<int, int> _recentErrorDigests = <int, int>{};
  static const int _dedupeTtlMs = 3000;

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

  /// Clears the current auth token
  static Future<void> clearToken() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.clearToken();
  }

  /// Starts a manual analytics session
  static Future<void> startSession() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.startSession();
  }

  /// Ends the current session
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

  /// Triggers a native crash for testing
  static Future<void> generateTestCrash() {
    _ensureRegistered();
    return AppAmbitSdkFlutterPlatform.instance.generateTestCrash();
  }

  /// Unified error logger.
  ///
  /// Use ONE API for both use cases:
  /// - Message-only:     logError(message: "error message")
  /// - Exception/stack:  logError(exception: e, stackTrace: st, properties: {...}, classFqn: ..., fileName: ..., lineNumber: ...)
  ///
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

    final StackTrace effectiveStack =
        stackTrace ?? (exception is Error && exception.stackTrace != null
            ? exception.stackTrace!
            : StackTrace.current);

    final String? stackStr = _normalizeStackTrace(exception, effectiveStack);

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

    final _CallSite inferred = _inferCallSite(effectiveStack);

    final String? finalClassFqn = (classFqn != null && classFqn.isNotEmpty)
        ? classFqn
        : inferred.classFqn;

    final String? finalFileName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : inferred.filePath;

    final int? finalLine = lineNumber ?? inferred.lineNumber;

    if (finalClassFqn != null && finalClassFqn.isNotEmpty) {
      payload['classFqn'] = finalClassFqn;
    }
    if (finalFileName != null && finalFileName.isNotEmpty) {
      payload['fileName'] = finalFileName;
    }
    if (finalLine != null) {
      payload['lineNumber'] = finalLine;
    }

    if (payload.isEmpty) return Future.value();

    final bool userProvidedMessage = message != null && message.isNotEmpty;

    final bool hasExceptionLike = (exception != null) || (stackStr != null && stackStr.isNotEmpty);
    if (hasExceptionLike) {
      final int digest = _computeDigest(exception: exception, message: messageStr, stackStr: stackStr);
      if (_isDuplicateDigest(digest)) {
        return Future.value();
      }
    }

    if (userProvidedMessage) {
      return AppAmbitSdkFlutterPlatform.instance.logErrorMessage(payload);
    } else if ((exception != null) || (stackStr != null && stackStr.isNotEmpty)) {
      return AppAmbitSdkFlutterPlatform.instance.logError(payload);
    } else {
      return Future.value();
    }
  }


  static String? _stringify(Object? value) {
    if (value == null) return null;
    try {
      return value.toString();
    } catch (_) {
      return '(${value.runtimeType})';
    }
  }


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

  static int _computeDigest({Object? exception, String? message, String? stackStr}) {
    final String a = exception?.runtimeType.toString() ?? '';
    final String b = (exception?.toString() ?? message ?? '').trim();
    final String c = (stackStr ?? '').split('\n').take(20).join('|');
    return Object.hashAll([a, b, c]);
  }

  static bool _isDuplicateDigest(int d) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    _recentErrorDigests.removeWhere((_, t) => (now - t) > _dedupeTtlMs);
    final bool seen = _recentErrorDigests.containsKey(d);
    if (!seen) _recentErrorDigests[d] = now;
    return seen;
  }
}

class _CallSite {
  final String? classFqn;
  final String? filePath;
  final int? lineNumber;
  const _CallSite({this.classFqn, this.filePath, this.lineNumber});
}

_CallSite _inferCallSite(StackTrace stack) {
  final lines = stack.toString().split('\n');
  final skipPrefixes = <String>[
    'dart:',
    'package:flutter/',
    'package:flutter_test/',
    'package:appambit_sdk_flutter/',
    'package:appambit_sdk/',
  ];

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final m = RegExp(r'^\#\d+\s+([^\s]+)\s+\((.+):(\d+)(?::\d+)?\)$').firstMatch(line);
    if (m == null) continue;
    final symbol = m.group(1) ?? '';
    final loc = m.group(2) ?? '';
    final ln = int.tryParse(m.group(3) ?? '');
    bool skip = false;
    for (final p in skipPrefixes) {
      if (loc.startsWith(p)) { skip = true; break; }
    }
    if (skip) continue;
    if (symbol.startsWith('AppambitSdk.') || symbol.contains('.logError')) continue;
    final filePath = _normalizePath(loc);
    final inferredClass = _symbolToClass(symbol) ?? _fallbackClassFromPath(filePath);
    return _CallSite(classFqn: inferredClass, filePath: filePath, lineNumber: ln);
  }

  return const _CallSite();
}

String _normalizePath(String loc) {
  if (loc.startsWith('file:')) {
    try { return Uri.parse(loc).toFilePath(); } catch (_) { return loc; }
  }
  return loc;
}

String? _symbolToClass(String symbol) {
  if (symbol.contains('.')) {
    final head = symbol.split('.').first;
    final cleaned = head.replaceAll('<anonymous closure>', '').trim();
    if (cleaned.isNotEmpty) return cleaned;
  }
  return null;
}

String? _fallbackClassFromPath(String path) {
  final slash = path.lastIndexOf('/');
  final back = path.lastIndexOf('\\');
  final idx = slash > back ? slash : back;
  final base = idx >= 0 ? path.substring(idx + 1) : path;
  final dot = base.lastIndexOf('.');
  final name = dot > 0 ? base.substring(0, dot) : base;
  return name.isNotEmpty ? name : null;
}
