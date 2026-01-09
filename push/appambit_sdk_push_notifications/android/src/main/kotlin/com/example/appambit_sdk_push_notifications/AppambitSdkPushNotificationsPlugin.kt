package com.example.appambit_sdk_push_notifications

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.appambit.sdk.PushNotifications

class AppambitSdkPushNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

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
            }
            "requestNotificationPermission" -> {
                val activity: Activity? = currentActivity
                if (activity is ComponentActivity) {
                    PushNotifications.requestNotificationPermission(activity)
                }
            }
            "setNotificationsEnabled" -> {
                PushNotifications.start(context)
            }
            "isNotificationsEnabled" -> {
                PushNotifications.start(context)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
