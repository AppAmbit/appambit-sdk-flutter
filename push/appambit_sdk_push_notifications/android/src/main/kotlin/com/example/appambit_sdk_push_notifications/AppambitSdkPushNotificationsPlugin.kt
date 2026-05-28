package com.example.appambit_sdk_push_notifications

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
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

        private const val PREFS_NAME         = "appambit_push_prefs"
        private const val KEY_HAS_PENDING    = "appambit_push_has_pending"
        private const val KEY_PENDING_ENABLED = "appambit_push_pending_enabled"
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
                // Boot the SDK so it registers its FCM token listener. We use PushKernel.start
                // (not PushNotifications.start) to avoid calling updateConsumer with a hardcoded
                // pushEnabled=true on every launch. The token listener below handles the cases
                // where a new token is needed (e.g. after deleteToken during offline disable).
                PushKernel.start(context)

                // Install a token listener so that when FCM delivers a new token (e.g. after
                // deleteToken was called during an offline disable), the correct enabled state
                // is synced to the backend via the public PushNotifications facade, which reads
                // the stored token internally. pushEnabled=null tells the facade to read the
                // stored enabled state from SharedPrefs.
                PushKernel.setTokenListener(object : PushKernel.TokenListener {
                    override fun onNewToken(token: String) {
                        // PushNotifications.setNotificationsEnabled reads the token from the
                        // SDK's own store — no getCurrentToken() needed here. handleNewToken
                        // deduplicates (if token == currentToken: return), so calling
                        // setNotificationsEnabled here does NOT cause an infinite loop.
                        PushNotifications.setNotificationsEnabled(
                            context,
                            PushKernel.isNotificationsEnabled(context)
                        )
                        clearPendingSync()
                    }
                })

                // Flush any state that couldn't be sent while offline.
                flushPendingSyncIfNeeded()

                installNotificationListenersIfNeeded()
                result.success(null)
            }
            "setNotificationsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                savePendingSync(enabled)
                if (isNetworkAvailable()) {
                    // Online: use the public facade — it updates SharedPrefs, DB, and backend.
                    PushNotifications.setNotificationsEnabled(context, enabled)
                    clearPendingSync()
                } else {
                    // Offline: only update in-memory / SharedPrefs state so this session is
                    // consistent. Do NOT call PushNotifications (which would write to DB and
                    // contaminate deduplication), leaving the DB at its previous value so that
                    // flushPendingSyncIfNeeded can detect the mismatch on the next online launch.
                    PushKernel.setNotificationsEnabled(context, enabled)
                }
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

    // MARK: - Pending sync

    private fun savePendingSync(enabled: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_HAS_PENDING, true)
            .putBoolean(KEY_PENDING_ENABLED, enabled)
            .apply()
    }

    private fun clearPendingSync() {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .remove(KEY_HAS_PENDING)
            .remove(KEY_PENDING_ENABLED)
            .apply()
    }

    // Flushes any consumer update that was deferred because the device was offline.
    //
    // For disable (enabled=false): PushNotifications.setNotificationsEnabled reads the
    // stored token from DB (the last valid FCM token before deleteToken was called).
    //
    // For enable (enabled=true) with no token yet: skipped here; the token listener
    // installed in "start" handles it when FCM delivers the new token, which happens
    // on the next online launch after deleteToken was called during offline disable.
    private fun flushPendingSyncIfNeeded() {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_HAS_PENDING, false)) return
        val enabled = prefs.getBoolean(KEY_PENDING_ENABLED, true)

        if (!isNetworkAvailable()) return

        if (!enabled) {
            // Disable: the stored FCM token in the DB is still valid (deleteToken only
            // clears the in-memory token, not the DB copy). The public facade reads it.
            PushNotifications.setNotificationsEnabled(context, false)
            clearPendingSync()
        }
        // Enable with no token: token listener fires when FCM delivers the new token.
        // PushKernel.isNotificationsEnabled will return true (set by PushKernel.setNotificationsEnabled
        // during the offline enable call), so onNewToken will call setNotificationsEnabled(true).
    }

    // MARK: - Network

    private fun isNetworkAvailable(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            cm.getNetworkCapabilities(cm.activeNetwork)
                ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        } else {
            @Suppress("DEPRECATION")
            cm.activeNetworkInfo?.isConnected == true
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
