import 'dart:async';
import 'dart:ui' as ui;

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppAmbitSdkFlutterPlatform extends AppAmbitSdkFlutterPlatform
    with MockPlatformInterfaceMixin {
  Map<String, dynamic>? lastCall;
  String? cancelledRequestId;
  Future<Map<dynamic, dynamic>> Function()? callHandler;
  final List<Map<String, dynamic>?> errorPayloads = [];
  final List<Map<String, dynamic>> messagePayloads = [];

  @override
  Future<void> startCore({required String appKey}) async {}

  @override
  Future<void> logError(Map<String, dynamic>? payload) async {
    errorPayloads.add(payload);
  }

  @override
  Future<void> logErrorMessage(Map<String, dynamic> payload) async {
    messagePayloads.add(payload);
  }

  @override
  Future<Map<dynamic, dynamic>> cloudCodeCall({
    required String requestId,
    required String function,
    required String method,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    lastCall = {
      'requestId': requestId,
      'function': function,
      'method': method,
      'query': query,
      'body': body,
      'headers': headers,
    };
    return callHandler?.call() ?? Future.value({});
  }

  @override
  Future<void> cloudCodeCancel(String requestId) async {
    cancelledRequestId = requestId;
  }
}

void main() {
  late MockAppAmbitSdkFlutterPlatform platform;

  setUp(() {
    platform = MockAppAmbitSdkFlutterPlatform();
    AppAmbitSdkFlutterPlatform.instance = platform;
  });

  test('forwards Cloud Code request and normalizes dynamic response', () async {
    platform.callHandler = () async => {
      'data': {
        'ok': true,
        'items': [1, 'two'],
      },
      'statusCode': 201,
      'requestId': 'req-1',
      'headers': {'X-Trace': 'trace-1'},
    };

    final response = await CloudCode.call(
      'demo-function',
      method: CloudCodeHttpMethod.patch,
      query: {'page': '2'},
      body: {
        'message': 'hello',
        'nested': {'enabled': true},
      },
      headers: {'X-Sample': 'flutter'},
    ).future;

    expect(platform.lastCall?['function'], 'demo-function');
    expect(platform.lastCall?['method'], 'PATCH');
    expect(platform.lastCall?['query'], {'page': '2'});
    expect(platform.lastCall?['body'], {
      'message': 'hello',
      'nested': {'enabled': true},
    });
    expect(response.statusCode, 201);
    expect(response.requestId, 'req-1');
    expect(response.headers, {'X-Trace': 'trace-1'});
    expect(response.data, {
      'ok': true,
      'items': [1, 'two'],
    });
  });

  test(
    'decodes a typed Cloud Code response without changing metadata',
    () async {
      platform.callHandler = () async => {
        'data': {'count': 7},
        'statusCode': 200,
        'requestId': 'req-typed',
        'headers': {'X-Request': 'typed'},
      };

      final result = await CloudCode.callTyped<int>(
        'summary',
        fromJson: (value) => (value as Map)['count'] as int,
      ).future;

      expect(result.data, 7);
      expect(result.statusCode, 200);
      expect(result.requestId, 'req-typed');
      expect(result.headers, {'X-Request': 'typed'});
    },
  );

  test('maps native Cloud Code error details', () async {
    platform.callHandler = () async {
      throw PlatformException(
        code: 'CLOUD_CODE_ERROR',
        message: 'Cloud Code returned HTTP 400.',
        details: {
          'code': 'HTTP',
          'statusCode': 400,
          'body': {'error': 'invalid'},
          'rawBody': null,
          'requestId': 'req-error',
        },
      );
    };

    final future = CloudCode.call('controlled-error').future;
    await expectLater(
      future,
      throwsA(
        isA<CloudCodeError>()
            .having((error) => error.code, 'code', CloudCodeErrorCode.http)
            .having((error) => error.statusCode, 'status', 400)
            .having((error) => error.requestId, 'request id', 'req-error'),
      ),
    );
  });

  test(
    'maps every native CloudCodeError.Code constant to its Dart counterpart',
    () async {
      // Mirrors the 14 constants of com.appambit.sdk.models.cloudcode.
      // CloudCodeError$Code, decompiled from the real appambit:1.2.0 AAR.
      const wireToDart = {
        'NOT_INITIALIZED': CloudCodeErrorCode.notInitialized,
        'INVALID_FUNCTION': CloudCodeErrorCode.invalidFunction,
        'INVALID_METHOD': CloudCodeErrorCode.invalidMethod,
        'INVALID_QUERY': CloudCodeErrorCode.invalidQuery,
        'INVALID_BODY': CloudCodeErrorCode.invalidBody,
        'INVALID_HEADER': CloudCodeErrorCode.invalidHeader,
        'INVALID_RESPONSE_TYPE': CloudCodeErrorCode.invalidResponseType,
        'CANCELLED': CloudCodeErrorCode.cancelled,
        'NETWORK_UNAVAILABLE': CloudCodeErrorCode.networkUnavailable,
        'TIMED_OUT': CloudCodeErrorCode.timedOut,
        'INVALID_URL': CloudCodeErrorCode.invalidUrl,
        'TRANSPORT': CloudCodeErrorCode.transport,
        'DECODING': CloudCodeErrorCode.decoding,
        'HTTP': CloudCodeErrorCode.http,
      };

      for (final entry in wireToDart.entries) {
        platform.callHandler = () async {
          throw PlatformException(
            code: 'CLOUD_CODE_ERROR',
            message: 'native error',
            details: {'code': entry.key},
          );
        };

        await expectLater(
          CloudCode.call('probe-${entry.key}').future,
          throwsA(
            isA<CloudCodeError>().having(
              (error) => error.code,
              'code',
              entry.value,
            ),
          ),
          reason: 'wire code ${entry.key} should map to ${entry.value}',
        );
      }
    },
  );

  test(
    'BAD_ARGS from a bridge (no structured details) maps to CloudCodeErrorCode.badArgs',
    () async {
      // Both CloudCodeFlutter.kt and CloudCodeFlutter.swift reply
      // result.error("BAD_ARGS", ..., details: null) for malformed
      // arguments - a platform-channel contract violation caught before the
      // native Cloud Code SDK is ever reached, distinct from any of its 14
      // error codes.
      platform.callHandler = () async {
        throw PlatformException(
          code: 'BAD_ARGS',
          message: "Missing 'requestId'",
        );
      };

      await expectLater(
        CloudCode.call('bad-args-probe').future,
        throwsA(
          isA<CloudCodeError>().having(
            (error) => error.code,
            'code',
            CloudCodeErrorCode.badArgs,
          ),
        ),
      );
    },
  );

  test('statusCode is null when the bridge sends no statusCode', () async {
    platform.callHandler = () async => {
      'data': null,
      'requestId': 'req-no-status',
      'headers': <String, String>{},
    };

    final response = await CloudCode.call('no-status-code').future;
    expect(response.statusCode, isNull);
  });

  test(
    'an unobserved cancellation never surfaces as an uncaught async error',
    () async {
      // Regression for the bug where cancel()'s completeError() would be
      // reported through the current Zone's error handler whenever nobody
      // awaited request.future - e.g. cancelling in dispose() without
      // awaiting the result.
      Object? uncaughtError;
      await runZonedGuarded(
        () async {
          final pending = Completer<Map<dynamic, dynamic>>();
          platform.callHandler = () => pending.future;

          final request = CloudCode.call('fire-and-forget');
          await request.cancel();
          // Deliberately never awaits/listens to request.future.
          await Future<void>.delayed(Duration.zero);
        },
        (error, stack) {
          uncaughtError = error;
        },
      );

      expect(uncaughtError, isNull);
    },
  );

  test('times out on the Dart side and cancels the native request', () async {
    final pending = Completer<Map<dynamic, dynamic>>();
    platform.callHandler = () => pending.future;

    final future = CloudCode.call(
      'slow-function',
      timeout: const Duration(milliseconds: 10),
    ).future;

    await expectLater(
      future,
      throwsA(
        isA<CloudCodeError>().having(
          (error) => error.code,
          'code',
          CloudCodeErrorCode.timedOut,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(platform.cancelledRequestId, isNotNull);
  });

  test('cancels a pending request through the platform bridge', () async {
    final pending = Completer<Map<dynamic, dynamic>>();
    platform.callHandler = () => pending.future;

    final request = CloudCode.call('slow-function');
    final resultFuture = expectLater(
      request.future,
      throwsA(
        isA<CloudCodeError>().having(
          (error) => error.code,
          'code',
          CloudCodeErrorCode.cancelled,
        ),
      ),
    );

    await request.cancel();
    await resultFuture;
    expect(platform.cancelledRequestId, isNotNull);
  });

  test('does not throttle explicit error messages', () async {
    await AppAmbitSdk.logError(message: 'first explicit error');
    await AppAmbitSdk.logError(message: 'second explicit error');

    expect(platform.messagePayloads, hasLength(2));
  });

  test(
    'does not throttle a burst of IDENTICAL explicit error messages',
    () async {
      // Regression: logError's automatic-error dedup window (3s) was
      // accidentally catching pure message-only calls too, because
      // effectiveStack falls back to StackTrace.current when no
      // exception/stackTrace is supplied, making every call look
      // "exception-like". Firing the same explicit message N times in a
      // burst (e.g. a test/demo button that logs 5 identical errors) used
      // to silently drop all but the first.
      final futures = List.generate(
        5,
        (_) => AppAmbitSdk.logError(message: 'same message every time'),
      );
      await Future.wait(futures);

      expect(platform.messagePayloads, hasLength(5));
    },
  );

  test('throttles a burst of automatic Flutter errors', () async {
    final previousFlutterError = FlutterError.onError;
    final previousPlatformError = ui.PlatformDispatcher.instance.onError;
    FlutterError.onError = (_) {};

    try {
      await AppAmbitSdk.start(appKey: 'test-app');
      final handler = FlutterError.onError!;

      for (var i = 0; i < 10; i++) {
        handler(
          FlutterErrorDetails(
            exception: StateError('burst error'),
            stack: StackTrace.fromString('stack-$i'),
          ),
        );
      }

      await Future<void>.delayed(Duration.zero);
      expect(platform.errorPayloads, hasLength(1));
    } finally {
      FlutterError.onError = previousFlutterError;
      ui.PlatformDispatcher.instance.onError = previousPlatformError;
    }
  });
}
