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
