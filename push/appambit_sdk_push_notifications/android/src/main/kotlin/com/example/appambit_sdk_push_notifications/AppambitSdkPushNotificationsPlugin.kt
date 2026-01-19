package com.example.appambit_sdk_push_notifications

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.appambit.sdk.PushNotifications

class AppambitSdkPushNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appambit_sdk_push_notifications")
        channel.setMethodCallHandler(this)
    }

    private var requestResult: Boolean = false

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when(call.method) {
            "start" -> {
                PushNotifications.start(context)
                result.success(null)
            }
            "setNotificationsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                PushNotifications.setNotificationsEnabled(context, enabled)
                result.success(null)
            }
            "isNotificationsEnabled" -> {
                val isEnabled = PushNotifications.isNotificationsEnabled(context)
                result.success(isEnabled)
            }
            "requestNotificationPermission" -> {
                handleNotificationPermissionRequest(result, false)
            }
            "requestNotificationPermissionWithResult" -> {
                handleNotificationPermissionRequest(result, true)
            }
            "setNotificationCustomizer" -> {
                PushNotifications.setNotificationCustomizer { _, _, notification ->
                    val payload = HashMap<String, Any?>()

                    val dataMap = HashMap<String, Any?>()
                    notification.data.forEach { (key, value) ->
                        dataMap[key] = value
                    }

                    val notificationMap = HashMap<String, Any?>()
                    notificationMap["title"] = notification.title
                    notificationMap["body"] = notification.body

                    payload["data"] = dataMap
                    payload["notification"] = notificationMap

                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        channel.invokeMethod("onNotificationReceived", payload)
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleNotificationPermissionRequest(result: Result, returnResult: Boolean) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "The current Activity is not available",
                null
            )
            return
        }

        if (Build.VERSION.SDK_INT < 33) {
            if (returnResult) result.success(true) else result.success(null)
            return
        }

        if (currentActivity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            if (returnResult) result.success(true) else result.success(null)
        } else {
            pendingResult = result
            requestResult = returnResult
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
            if (requestResult) {
                pendingResult?.success(granted)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity?.let {
             if (activity is ActivityPluginBinding) {
                 (activity as ActivityPluginBinding).removeRequestPermissionsResultListener(this)
             }
        }
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
         activity?.let {
             if (activity is ActivityPluginBinding) {
                 (activity as ActivityPluginBinding).removeRequestPermissionsResultListener(this)
             }
        }
        activity = null
    }
}
