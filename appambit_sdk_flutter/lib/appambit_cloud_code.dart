import 'dart:async';

import 'package:flutter/services.dart';

import 'appambit_sdk_flutter_method_channel.dart' as impl;
import 'appambit_sdk_flutter_platform_interface.dart';

enum CloudCodeHttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const CloudCodeHttpMethod(this.wireName);

  final String wireName;
}

enum CloudCodeErrorCode {
  notInitialized,
  invalidFunction,
  invalidMethod,
  invalidQuery,
  invalidBody,
  invalidHeader,
  invalidResponseType,
  cancelled,
  networkUnavailable,
  timedOut,
  invalidUrl,
  transport,
  decoding,
  http,
  /// The native bridge rejected the platform-channel call itself (e.g. a
  /// missing `correlationId`) before ever reaching the native Cloud Code SDK.
  badArgs,
  unknown,
}

class CloudCodeResponse {
  final Object? data;
  final int? statusCode;
  final String? requestId;
  final Map<String, String> headers;

  const CloudCodeResponse({
    required this.data,
    required this.statusCode,
    required this.requestId,
    required this.headers,
  });
}

class CloudCodeResult<T> {
  final T? data;
  final int? statusCode;
  final String? requestId;
  final Map<String, String> headers;

  const CloudCodeResult({
    required this.data,
    required this.statusCode,
    required this.requestId,
    required this.headers,
  });
}

class CloudCodeError implements Exception {
  final CloudCodeErrorCode code;
  final String message;
  final String? function;
  final String? header;
  final int? statusCode;
  final Object? body;
  final String? rawBody;
  final String? requestId;

  const CloudCodeError({
    required this.code,
    required this.message,
    this.function,
    this.header,
    this.statusCode,
    this.body,
    this.rawBody,
    this.requestId,
  });

  factory CloudCodeError.cancelled() {
    return const CloudCodeError(
      code: CloudCodeErrorCode.cancelled,
      message: 'Cloud Code request was cancelled.',
    );
  }

  factory CloudCodeError.invalidBody(Object cause) {
    return CloudCodeError(
      code: CloudCodeErrorCode.invalidBody,
      message: 'The Cloud Code body is not valid JSON: $cause',
    );
  }

  factory CloudCodeError.transport(Object cause) {
    return CloudCodeError(
      code: CloudCodeErrorCode.transport,
      message: 'Cloud Code network request failed: $cause',
    );
  }

  factory CloudCodeError.decoding(Object cause) {
    return CloudCodeError(
      code: CloudCodeErrorCode.decoding,
      message: 'Cloud Code response could not be decoded: $cause',
    );
  }

  factory CloudCodeError.fromPlatformException(PlatformException error) {
    final details = _asStringKeyedMap(error.details);
    final rawCode = details['code'] ?? error.code;
    return CloudCodeError(
      code: _errorCodeFromWire(rawCode),
      message:
          (details['message'] ?? error.message ?? 'Cloud Code request failed')
              .toString(),
      function: details['function'] as String?,
      header: details['header'] as String?,
      statusCode: _asInt(details['statusCode']),
      body: _normalizeValue(details['body']),
      rawBody: details['rawBody'] as String?,
      requestId: details['requestId'] as String?,
    );
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' status=$statusCode';
    final request = requestId == null ? '' : ' requestId=$requestId';
    return 'CloudCodeError(${code.name}$status$request): $message';
  }
}

class CloudCodeRequest<T> {
  final Future<T> future;
  final Future<void> Function() _cancelNative;
  final Completer<T> _completer;
  bool _completed = false;
  bool _cancelRequested = false;

  CloudCodeRequest._internal(this.future, this._completer, this._cancelNative);

  factory CloudCodeRequest._create(
    Future<T> operation,
    Future<void> Function() cancelNative,
  ) {
    final completer = Completer<T>();
    final request = CloudCodeRequest<T>._internal(
      completer.future,
      completer,
      cancelNative,
    );

    // `request.future` (== completer.future) is not necessarily awaited by
    // the caller - e.g. firing a request and cancelling it in dispose()
    // without awaiting the result. Without an observer here, an error (most
    // commonly CloudCodeError.cancelled() from cancel()) would surface as an
    // uncaught async error in the current Zone, and once AppAmbitSdk.start()
    // has installed its PlatformDispatcher.onError hook, get auto-reported
    // to the dashboard as a customer app error. ignore() only marks the
    // future as observed; real callers that do await/listen still receive
    // the error normally through their own subscription.
    request.future.ignore();

    operation.then(
      request._complete,
      onError: (Object error, StackTrace stack) {
        request._completeError(error, stack);
      },
    );
    return request;
  }

  Future<void> cancel() async {
    if (_completed || _cancelRequested) return;
    _cancelRequested = true;
    _completed = true;
    _completer.completeError(CloudCodeError.cancelled());
    await _cancelNative();
  }

  void _complete(T value) {
    if (_completed) return;
    _completed = true;
    _completer.complete(value);
  }

  void _completeError(Object error, StackTrace stack) {
    if (_completed) return;
    _completed = true;
    _completer.completeError(error, stack);
  }
}

class CloudCode {
  CloudCode._();

  static int _requestSequence = 0;

  static CloudCodeRequest<CloudCodeResponse> call(
    String function, {
    CloudCodeHttpMethod method = CloudCodeHttpMethod.post,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    impl.registerMethodChannelImplementation();

    // Internal only - never returned to callers. Needed because MethodChannel
    // is a stateless RPC: unlike the native SDKs (which cancel by holding a
    // token/Task object reference), Dart has to hand the native bridge a
    // string key it can use to find this call again on cancel(). Distinct
    // from CloudCodeResponse.requestId, which is the server's request id.
    final correlationId = _nextCorrelationId();
    final snapshot = _snapshotRequest(query, body, headers);
    if (snapshot.error != null) {
      return CloudCodeRequest._create(
        Future<CloudCodeResponse>.error(snapshot.error!),
        () async {},
      );
    }

    final platform = AppAmbitSdkFlutterPlatform.instance;
    Future<void> cancelNative() =>
        platform.cloudCodeCancel(correlationId);
    var operation = _invoke(
      platform.cloudCodeCall(
        correlationId: correlationId,
        function: function,
        method: method.wireName,
        query: snapshot.query,
        body: snapshot.body,
        headers: snapshot.headers,
      ),
    );

    if (timeout != null) {
      operation = operation.timeout(
        timeout,
        onTimeout: () {
          unawaited(cancelNative());
          throw CloudCodeError(
            code: CloudCodeErrorCode.timedOut,
            message: 'Cloud Code request timed out after $timeout.',
            function: function,
            requestId: correlationId,
          );
        },
      );
    }

    return CloudCodeRequest._create(operation, cancelNative);
  }

  static CloudCodeRequest<CloudCodeResult<T>> callTyped<T>(
    String function, {
    CloudCodeHttpMethod method = CloudCodeHttpMethod.post,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    required T Function(Object? value) fromJson,
  }) {
    final request = call(
      function,
      method: method,
      query: query,
      body: body,
      headers: headers,
      timeout: timeout,
    );

    final typedOperation = request.future.then((response) {
      if (response.data == null) {
        return CloudCodeResult<T>(
          data: null,
          statusCode: response.statusCode,
          requestId: response.requestId,
          headers: response.headers,
        );
      }

      try {
        return CloudCodeResult<T>(
          data: fromJson(response.data),
          statusCode: response.statusCode,
          requestId: response.requestId,
          headers: response.headers,
        );
      } catch (error) {
        throw CloudCodeError.decoding(error);
      }
    });

    return CloudCodeRequest._create(typedOperation, request.cancel);
  }

  static Future<CloudCodeResponse> _invoke(
    Future<Map<dynamic, dynamic>> operation,
  ) async {
    try {
      final raw = await operation;
      final map = _asStringKeyedMap(raw);
      return CloudCodeResponse(
        data: _normalizeValue(map['data']),
        statusCode: _asInt(map['statusCode']),
        requestId: map['requestId'] as String?,
        headers: _asStringMap(map['headers']),
      );
    } on PlatformException catch (error) {
      throw CloudCodeError.fromPlatformException(error);
    } catch (error) {
      throw CloudCodeError.transport(error);
    }
  }

  static String _nextCorrelationId() {
    _requestSequence = (_requestSequence + 1) & 0x7fffffff;
    return 'flutter-${DateTime.now().microsecondsSinceEpoch}-$_requestSequence';
  }
}

class _RequestSnapshot {
  final Map<String, String>? query;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final CloudCodeError? error;

  const _RequestSnapshot({this.query, this.body, this.headers, this.error});
}

_RequestSnapshot _snapshotRequest(
  Map<String, String>? query,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
) {
  try {
    final copiedBody = body == null ? null : _snapshotMap(body);
    return _RequestSnapshot(
      query: query == null ? null : Map<String, String>.from(query),
      body: copiedBody,
      headers: headers == null ? null : Map<String, String>.from(headers),
    );
  } catch (error) {
    return _RequestSnapshot(error: CloudCodeError.invalidBody(error));
  }
}

Map<String, dynamic> _snapshotMap(Map<String, dynamic> value) {
  return value.map((key, item) {
    if (key.isEmpty) throw ArgumentError('JSON object keys cannot be empty');
    return MapEntry(key, _snapshotJsonValue(item));
  });
}

Object? _snapshotJsonValue(Object? value) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is List) {
    return value.map(_snapshotJsonValue).toList(growable: false);
  }
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String || (entry.key as String).isEmpty) {
        throw ArgumentError('JSON object keys must be non-empty strings');
      }
      result[entry.key as String] = _snapshotJsonValue(entry.value);
    }
    return result;
  }
  throw ArgumentError('Unsupported JSON value: ${value.runtimeType}');
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map<String, dynamic>((key, item) {
    return MapEntry(key.toString(), _normalizeValue(item));
  });
}

Map<String, String> _asStringMap(Object? value) {
  final map = _asStringKeyedMap(value);
  return map.map((key, item) => MapEntry(key, item?.toString() ?? ''));
}

Object? _normalizeValue(Object? value) {
  if (value is Map) return _asStringKeyedMap(value);
  if (value is List) return value.map(_normalizeValue).toList(growable: false);
  return value;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

CloudCodeErrorCode _errorCodeFromWire(Object? value) {
  final normalized = value
      ?.toString()
      .replaceAll('-', '_')
      .replaceAll('.', '_')
      .toUpperCase();
  switch (normalized) {
    case 'NOT_INITIALIZED':
      return CloudCodeErrorCode.notInitialized;
    case 'INVALID_FUNCTION':
      return CloudCodeErrorCode.invalidFunction;
    case 'INVALID_METHOD':
      return CloudCodeErrorCode.invalidMethod;
    case 'INVALID_QUERY':
      return CloudCodeErrorCode.invalidQuery;
    case 'INVALID_BODY':
      return CloudCodeErrorCode.invalidBody;
    case 'INVALID_HEADER':
      return CloudCodeErrorCode.invalidHeader;
    case 'INVALID_RESPONSE_TYPE':
      return CloudCodeErrorCode.invalidResponseType;
    case 'CANCELLED':
      return CloudCodeErrorCode.cancelled;
    case 'NETWORK_UNAVAILABLE':
      return CloudCodeErrorCode.networkUnavailable;
    case 'TIMED_OUT':
      return CloudCodeErrorCode.timedOut;
    case 'INVALID_URL':
      return CloudCodeErrorCode.invalidUrl;
    case 'TRANSPORT':
      return CloudCodeErrorCode.transport;
    case 'DECODING':
      return CloudCodeErrorCode.decoding;
    case 'HTTP':
      return CloudCodeErrorCode.http;
    case 'BAD_ARGS':
      return CloudCodeErrorCode.badArgs;
    default:
      return CloudCodeErrorCode.unknown;
  }
}
