package com.example.appambit_sdk_push_notifications

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.appambit.sdk.PushKernel
import com.appambit.sdk.PushNotifications
import com.appambit.sdk.models.AppAmbitNotification
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class AppambitSdkPushNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.NewIntentListener {

    companion object {
        // Mirror the package-private constants from MessagingService so warm-start
        // intent parsing works without depending on SDK internals.
        private const val ACTION_NOTIFICATION_OPENED = "com.appambit.sdk.NOTIFICATION_OPENED"
        private const val EXTRA_TITLE      = "appambit_title"
        private const val EXTRA_BODY       = "appambit_body"
        private const val EXTRA_COLOR      = "appambit_color"
        private const val EXTRA_ICON       = "appambit_icon"
        private const val EXTRA_IMAGE_URL  = "appambit_image_url"
        private const val EXTRA_DATA_KEYS  = "appambit_data_keys"
        private const val EXTRA_DATA_VALUES = "appambit_data_keys_values"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var listenersInstalled = false

    // Registered as the PushKernel opened-listener in onAttachedToEngine so cold-start
    // taps (handleNotificationOpened fires from onAttachedToActivity, before the Dart
    // entrypoint has run setOpenedListener) are captured. The proxy buffers them until
    // Dart calls "setOpenedListener" and the channel callback is wired (see onMethodCall),
    // at which point the buffered tap is replayed. Wiring the callback here instead would
    // race the Dart side and drop cold-start taps, since invokeMethod has no handler yet.
    private val openedProxy = OpenedProxy()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appambit_sdk_push_notifications")
        channel.setMethodCallHandler(this)
        PushKernel.setOpenedNotificationListener(openedProxy)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "start" -> {
                // Use the decoupled PushKernel (not PushNotifications.start) so the FCM token
                // is fetched WITHOUT updating the consumer on every launch. PushNotifications
                // .setNotificationsEnabled is what syncs the consumer, only on user toggle.
                PushKernel.start(context)
                installNotificationListenersIfNeeded()
                result.success(null)
            }
            "setNotificationsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                // Updates the AppAmbit consumer on the backend (only invoked on user toggle).
                PushNotifications.setNotificationsEnabled(context, enabled)
                result.success(null)
            }
            "isNotificationsEnabled" -> {
                result.success(PushKernel.isNotificationsEnabled(context))
            }
            "requestNotificationPermission" -> {
                handleNotificationPermissionRequest(result)
            }
            "hasNotificationPermission" -> {
                val hasPermission = if (Build.VERSION.SDK_INT >= 33) {
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }
                result.success(hasPermission)
            }
            "setForegroundListener" -> {
                installNotificationListenersIfNeeded()
                result.success(null)
            }
            "setOpenedListener" -> {
                // Dart is now ready to receive opened taps: wire the channel callback,
                // which also flushes any cold-start tap buffered by openedProxy.
                openedProxy.setCallback { notification ->
                    mainHandler.post {
                        channel.invokeMethod("onOpenedNotification", PushPayloadMapper.payloadOf(notification))
                    }
                }
                installNotificationListenersIfNeeded()
                result.success(null)
            }
            "setBackgroundHandler" -> {
                val args = call.arguments as? Map<*, *>
                val dispatcherHandle = (args?.get("dispatcherHandle") as? Number)?.toLong()
                val handlerHandle = (args?.get("handlerHandle") as? Number)?.toLong()
                if (dispatcherHandle == null || handlerHandle == null) {
                    result.error(
                        "INVALID_ARGS",
                        "setBackgroundHandler requires dispatcherHandle and handlerHandle.",
                        null
                    )
                } else {
                    AppambitFlutterPushExtension.saveHandles(context, dispatcherHandle, handlerHandle)
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - Notification listeners

    private fun installNotificationListenersIfNeeded() {
        if (listenersInstalled) return
        listenersInstalled = true

        PushKernel.setForegroundNotificationListener(object : PushKernel.ForegroundNotificationListener {
            override fun onForegroundNotificationReceived(notification: AppAmbitNotification) {
                mainHandler.post {
                    channel.invokeMethod("onForegroundNotification", PushPayloadMapper.payloadOf(notification))
                }
            }
        })
        // openedProxy is already installed on PushKernel in onAttachedToEngine.
    }

    // MARK: - Permission

    private fun handleNotificationPermissionRequest(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "The current Activity is not available", null)
            return
        }

        if (Build.VERSION.SDK_INT < 33) {
            result.success(true)
            return
        }

        if (currentActivity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
        } else {
            pendingResult = result
            ActivityCompat.requestPermissions(
                currentActivity,
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                101
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == 101) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
            return true
        }
        return false
    }

    // MARK: - Flutter lifecycle

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        // Cold-start tap: the activity was launched from a notification.
        // openedProxy buffers the result if PushKernel.start() hasn't run yet.
        binding.activity.intent?.let {
            PushKernel.handleNotificationOpened(binding.activity, it)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        // Warm-start tap: the activity is already running and a notification
        // brought it to the foreground. Bypass the PushKernel → openedProxy chain
        // and invoke the channel directly so the delivery is not affected by any
        // intermediate listener state during the background→foreground transition.
        if (intent.action == ACTION_NOTIFICATION_OPENED) {
            val notification = notificationFromIntent(intent)
            mainHandler.post {
                channel.invokeMethod("onOpenedNotification", PushPayloadMapper.payloadOf(notification))
            }
        }
        return false
    }

    private fun notificationFromIntent(intent: Intent): AppAmbitNotification {
        val keys   = intent.getStringArrayExtra(EXTRA_DATA_KEYS)
        val values = intent.getStringArrayExtra(EXTRA_DATA_VALUES)
        val data   = mutableMapOf<String, String>()
        if (keys != null && values != null) {
            for (i in keys.indices) if (i < values.size) data[keys[i]] = values[i]
        }
        return AppAmbitNotification(
            intent.getStringExtra(EXTRA_TITLE),
            intent.getStringExtra(EXTRA_BODY),
            intent.getStringExtra(EXTRA_COLOR),
            intent.getStringExtra(EXTRA_ICON),
            intent.getStringExtra(EXTRA_IMAGE_URL),
            data
        )
    }

    // MARK: - Opened notification buffering proxy

    private class OpenedProxy : PushKernel.OpenedNotificationListener {
        @Volatile private var callback: ((AppAmbitNotification) -> Unit)? = null
        @Volatile private var buffered: AppAmbitNotification? = null

        fun setCallback(cb: (AppAmbitNotification) -> Unit) {
            callback = cb
            val buf = buffered
            if (buf != null) {
                buffered = null
                cb(buf)
            }
        }

        override fun onOpenedNotification(notification: AppAmbitNotification) {
            val cb = callback
            if (cb != null) {
                cb(notification)
            } else {
                buffered = notification
            }
        }
    }
}
