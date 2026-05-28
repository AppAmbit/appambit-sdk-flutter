import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'appambit_sdk_push_notifications_platform_interface.dart';
import 'src/push_notification_data.dart';

class MethodChannelAppambitSdkPushNotifications
    extends AppambitSdkPushNotificationsPlatform {
  final MethodChannel _channel = const MethodChannel(
    'appambit_sdk_push_notifications',
  );

  PushNotificationListener? _foreground;
  PushNotificationListener? _opened;
  bool _handlerInstalled = false;

  void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onForegroundNotification':
          _foreground?.call(_decode(call.arguments));
          break;
        case 'onOpenedNotification':
          _opened?.call(_decode(call.arguments));
          break;
      }
    });
  }

  PushNotificationData _decode(dynamic arguments) {
    if (arguments is Map) {
      return PushNotificationData.fromMap(arguments);
    }
    return const PushNotificationData();
  }

  @override
  Future<void> start() async {
    _ensureHandler();
    await _channel.invokeMethod<void>('start');
  }

  @override
  Future<void> requestNotificationPermission({
    PermissionResultCallback? callback,
  }) async {
    final bool? granted =
        await _channel.invokeMethod<bool>('requestNotificationPermission');
    callback?.call(granted ?? false);
  }

  @override
  Future<bool> hasNotificationPermission() async {
    final bool? value = await _channel.invokeMethod<bool>('hasNotificationPermission');
    return value ?? false;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _channel.invokeMethod<void>(
      'setNotificationsEnabled',
      {'enabled': enabled},
    );
  }

  @override
  Future<bool> isNotificationsEnabled() async {
    final bool? value =
        await _channel.invokeMethod<bool>('isNotificationsEnabled');
    return value ?? false;
  }

  @override
  void setForegroundListener(PushNotificationListener listener) {
    _ensureHandler();
    _foreground = listener;
    _channel.invokeMethod<void>('setForegroundListener');
  }

  @override
  void setOpenedListener(PushNotificationListener listener) {
    _ensureHandler();
    _opened = listener;
    _channel.invokeMethod<void>('setOpenedListener');
  }

  @override
  Future<void> setBackgroundHandler(PushNotificationListener listener) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
        '[AppAmbitPushFlutter] PushNotificationsSdk.Android.setBackgroundHandler '
        'is a no-op on iOS. Implement a Notification Service Extension in Swift '
        '(subclass AppAmbitNotificationService) instead.',
      );
      return;
    }

    final handlerHandle = PluginUtilities.getCallbackHandle(listener);
    if (handlerHandle == null) {
      throw ArgumentError(
        'PushNotificationsSdk.Android.setBackgroundHandler requires a top-level '
        'or static function annotated with @pragma("vm:entry-point").',
      );
    }

    final dispatcherHandle =
        PluginUtilities.getCallbackHandle(_backgroundDispatcher);
    if (dispatcherHandle == null) {
      throw StateError(
        'Unable to obtain the plugin background dispatcher callback handle.',
      );
    }

    await _channel.invokeMethod<void>('setBackgroundHandler', {
      'dispatcherHandle': dispatcherHandle.toRawHandle(),
      'handlerHandle': handlerHandle.toRawHandle(),
    });
  }
}

/// Entry point executed in a background Dart isolate when a push arrives
/// while the app is in background or killed on Android.
///
/// The native [AppambitFlutterPushExtension] boots a headless `FlutterEngine`
/// pointing at this function, then invokes the user handler over a dedicated
/// MethodChannel. The user's `@pragma('vm:entry-point')` handler is looked
/// up via [PluginUtilities.getCallbackFromHandle] using the handle saved
/// at registration time.
@pragma('vm:entry-point')
void _backgroundDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel bgChannel =
      MethodChannel('appambit_sdk_push_notifications_bg');
  bgChannel.setMethodCallHandler((call) async {
    if (call.method != 'onBackground') return;
    final args = call.arguments;
    if (args is! Map) return;
    final handlerHandle = args['handlerHandle'];
    if (handlerHandle is! int) return;

    final callback = PluginUtilities.getCallbackFromHandle(
      CallbackHandle.fromRawHandle(handlerHandle),
    );
    if (callback == null) {
      debugPrint(
        '[AppAmbitPushFlutter] Background handler callback not found for '
        'handle $handlerHandle. Was it tree-shaken? Add @pragma("vm:entry-point").',
      );
      return;
    }

    final payload = args['payload'];
    final data = payload is Map
        ? PushNotificationData.fromMap(payload)
        : const PushNotificationData();

    try {
      (callback as PushNotificationListener)(data);
    } catch (e, stack) {
      debugPrint('[AppAmbitPushFlutter] Background handler threw: $e\n$stack');
    }
  });
}
