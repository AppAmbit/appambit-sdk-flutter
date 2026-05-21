import 'appambit_sdk_push_notifications_platform_interface.dart';

export 'src/push_notification_data.dart';
export 'appambit_sdk_push_notifications_platform_interface.dart'
    show PushNotificationListener, PermissionResultCallback;

/// Cross-platform facade for AppAmbit push notifications.
///
/// API mirrors the .NET MAUI SDK (`AppAmbit.PushNotifications`). Method names
/// are cross-platform when the feature is supported on both Android and iOS,
/// even when the underlying mechanism differs. Platform-specific surface lives
/// under nested namespaces (e.g. [PushNotificationsSdk.Android]).
///
/// **Initialization order**
///
/// The AppAmbit core SDK must be initialized before [start] is called. On
/// iOS, [start] also requires the host app to have called
/// `application(_:didFinishLaunchingWithOptions:)` and registered for remote
/// notifications via the iOS plugin.
class PushNotificationsSdk {
  PushNotificationsSdk._();

  /// Android-only API surface. iOS equivalents live in the Notification
  /// Service Extension (see `AppAmbitPushSDK` in the iOS SDK).
  // ignore: constant_identifier_names
  static const Android = PushNotificationsAndroid._();

  /// Starts the push notifications module.
  ///
  /// Must be called after the core AppAmbit SDK is initialized. Registers
  /// the device for APNs (iOS) / FCM (Android) and uploads the resulting
  /// token to the AppAmbit backend.
  ///
  /// Available on: **Android + iOS**.
  static Future<void> start() =>
      AppambitSdkPushNotificationsPlatform.instance.start();

  /// Requests OS permission to display notifications.
  ///
  /// On Android 13+ this triggers the `POST_NOTIFICATIONS` runtime prompt.
  /// On earlier Android versions and on iOS, this prompts the user (iOS) or
  /// returns the current grant status (Android < 13) via [callback].
  ///
  /// The optional [callback] is invoked with the final grant result. If the
  /// user has already answered, the system may resolve immediately without
  /// showing a prompt.
  ///
  /// Available on: **Android + iOS**.
  static Future<void> requestNotificationPermission({
    PermissionResultCallback? callback,
  }) =>
      AppambitSdkPushNotificationsPlatform.instance
          .requestNotificationPermission(callback: callback);

  /// Returns whether the user has granted OS-level permission to display
  /// notifications for this app.
  ///
  /// This reflects the OS toggle only. To also account for the in-SDK
  /// enable/disable flag, combine with [isNotificationsEnabled].
  ///
  /// Available on: **Android + iOS**.
  static Future<bool> hasSystemPermission() =>
      AppambitSdkPushNotificationsPlatform.instance.hasSystemPermission();

  /// Enables or disables push delivery at the SDK level.
  ///
  /// When disabled, the SDK suppresses delivery of notifications even if
  /// the OS permission is granted. Use this for an in-app "Notifications"
  /// preference toggle. Independent of the OS permission state.
  ///
  /// Available on: **Android + iOS**.
  static Future<void> setNotificationsEnabled(bool enabled) =>
      AppambitSdkPushNotificationsPlatform.instance
          .setNotificationsEnabled(enabled);

  /// Returns the current SDK-level enabled state set via
  /// [setNotificationsEnabled]. Does **not** reflect the OS permission
  /// (use [hasSystemPermission] for that).
  ///
  /// Available on: **Android + iOS**.
  static Future<bool> isNotificationsEnabled() =>
      AppambitSdkPushNotificationsPlatform.instance.isNotificationsEnabled();

  /// Registers a listener invoked when a notification arrives while the app
  /// is in the foreground.
  ///
  /// Replaces any previously registered foreground listener.
  ///
  /// Available on: **Android + iOS**.
  static void setForegroundListener(PushNotificationListener listener) =>
      AppambitSdkPushNotificationsPlatform.instance
          .setForegroundListener(listener);

  /// Registers a listener invoked when the user taps a notification and
  /// the app is brought to the foreground.
  ///
  /// Replaces any previously registered opened listener. If the app was
  /// launched from a tap on a cold start, the listener fires once the
  /// Flutter engine is ready.
  ///
  /// Available on: **Android + iOS**.
  static void setOpenedListener(PushNotificationListener listener) =>
      AppambitSdkPushNotificationsPlatform.instance.setOpenedListener(listener);
}

/// Android-only push APIs. Access via [PushNotificationsSdk.Android].
///
/// The iOS equivalents are not exposed in Dart because iOS runs background
/// notification work in the Notification Service Extension (NSE), a separate
/// process without a Flutter engine. Subclass `AppAmbitNotificationService`
/// in your NSE Swift target for iOS background customization.
class PushNotificationsAndroid {
  const PushNotificationsAndroid._();

  /// Registers a handler invoked when a push arrives while the app is in
  /// background or has been killed by the system.
  ///
  /// The handler runs in a dedicated background Dart isolate (no UI, no
  /// shared state with the main isolate). It must be a **top-level** or
  /// **static** function annotated with `@pragma('vm:entry-point')` so the
  /// AOT compiler does not tree-shake it out of release builds.
  ///
  /// ```dart
  /// @pragma('vm:entry-point')
  /// void myBackgroundHandler(PushNotificationData data) {
  ///   // analytics, local DB writes, etc.
  /// }
  ///
  /// await PushNotificationsSdk.Android.setBackgroundHandler(myBackgroundHandler);
  /// ```
  ///
  /// Throws [ArgumentError] if [handler] is not a valid entry-point function.
  ///
  /// **Android-only.** Calling this on iOS is a no-op (logs a debug warning);
  /// for iOS background work, subclass `AppAmbitNotificationService` in your
  /// Notification Service Extension target.
  Future<void> setBackgroundHandler(PushNotificationListener handler) =>
      AppambitSdkPushNotificationsPlatform.instance
          .setBackgroundHandler(handler);
}
