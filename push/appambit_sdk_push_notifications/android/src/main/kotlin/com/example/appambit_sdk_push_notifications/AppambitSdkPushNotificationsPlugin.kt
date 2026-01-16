package com.example.appambit_sdk_push_notifications

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.ComponentActivity
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
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appambit_sdk_push_notifications")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when(call.method) {
            "start" -> {
                PushNotifications.start(context)
                result.success(null)
            }
            "requestNotificationPermission" -> {
                val currentActivity = activity
                 if (currentActivity != null) {
                    if (Build.VERSION.SDK_INT >= 33) {
                        if (currentActivity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(currentActivity, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                        }
                    }
                }
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
            "requestNotificationPermissionWithResult" -> {
                val currentActivity = activity
                if (currentActivity != null) {
                    if (Build.VERSION.SDK_INT >= 33) {
                        if (currentActivity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(currentActivity, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                        }
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
