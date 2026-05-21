package com.example.appambit_sdk_push_notifications

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.appambit.sdk.IAppAmbitNotificationServiceExtension
import com.appambit.sdk.models.AppAmbitNotification
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/// Bridge that lets the AppAmbit Android SDK invoke a Dart callback when a
/// push arrives while the app is in background or killed.
///
/// The Android SDK locates this class via the meta-data declared in the
/// plugin's AndroidManifest:
/// ```
/// <meta-data android:name="com.appambit.sdk.NotificationServiceExtension"
///            android:value="com.example.appambit_sdk_push_notifications.AppambitFlutterPushExtension"/>
/// ```
/// On a background push the SDK instantiates this class via reflection in the
/// MessagingService process and calls `onNotificationBackground(...)`. We:
///
/// 1. Read the Dart callback handles persisted by `setBackgroundHandler`.
/// 2. Boot a headless `FlutterEngine` and execute the `_backgroundDispatcher`
///    entry point.
/// 3. Send the notification payload over a dedicated MethodChannel.
///
/// Devs who need to extend this behavior can subclass and override
/// `onNotificationBackground`, calling `super` to preserve the Dart bridge.
open class AppambitFlutterPushExtension : IAppAmbitNotificationServiceExtension {

    companion object {
        private const val TAG = "AppAmbitPushFlutter"
        private const val PREFS = "appambit_push_bg"
        private const val KEY_DISPATCHER = "dispatcher_handle"
        private const val KEY_HANDLER = "handler_handle"
        private const val BG_CHANNEL = "appambit_sdk_push_notifications_bg"

        fun saveHandles(context: Context, dispatcherHandle: Long, handlerHandle: Long) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putLong(KEY_DISPATCHER, dispatcherHandle)
                .putLong(KEY_HANDLER, handlerHandle)
                .apply()
        }

        fun clearHandles(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY_DISPATCHER)
                .remove(KEY_HANDLER)
                .apply()
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    // The interface declares two overloads for each event: a `(notification)`
    // abstract version (required) and a `(context, notification)` default that
    // delegates to the abstract one. We override only the `(context, notification)`
    // form because we need the context to bootstrap the Flutter engine, but
    // Kotlin requires implementing the abstract single-arg version too — leave
    // it as a no-op delegation guard.

    override fun onNotificationBackground(notification: AppAmbitNotification) {
        Log.w(TAG, "Single-arg onNotificationBackground called; ignoring (context required).")
    }

    override fun onNotificationForeground(notification: AppAmbitNotification) {
        // Foreground is delivered via the in-memory listener while the main
        // engine is alive; no-op here.
    }

    override fun onNotificationBackground(context: Context, notification: AppAmbitNotification) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_DISPATCHER) || !prefs.contains(KEY_HANDLER)) {
            Log.d(TAG, "No background handler registered; skipping Dart dispatch.")
            return
        }
        val dispatcher = prefs.getLong(KEY_DISPATCHER, 0L)
        val handler = prefs.getLong(KEY_HANDLER, 0L)

        mainHandler.post {
            try {
                ensureEngine(context.applicationContext, dispatcher)
                channel?.invokeMethod(
                    "onBackground",
                    mapOf(
                        "handlerHandle" to handler,
                        "payload" to PushPayloadMapper.payloadOf(notification)
                    )
                )
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to dispatch background notification to Dart", t)
            }
        }
    }

    override fun onNotificationForeground(context: Context, notification: AppAmbitNotification) {
        // Foreground is delivered via the in-memory listener installed by
        // AppambitSdkPushNotificationsPlugin while the main engine is alive.
    }

    private fun ensureEngine(context: Context, dispatcherHandle: Long) {
        if (engine != null) return

        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
        }

        val info = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (info == null) {
            Log.e(TAG, "No Dart callback info for dispatcher handle $dispatcherHandle")
            return
        }

        val flutterEngine = FlutterEngine(context)
        val bundlePath = loader.findAppBundlePath()
        val callback = DartExecutor.DartCallback(context.assets, bundlePath, info)
        flutterEngine.dartExecutor.executeDartCallback(callback)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL)
        engine = flutterEngine
    }
}
