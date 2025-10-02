package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.Analytics
import com.appambit.sdk.Crashes
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AnalyticsFlutter {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/analytics")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableManualSession" -> Analytics.enableManualSession()
                "startSession" -> Analytics.startSession()
                "endSession" -> Analytics.endSession()
                "setUserId" -> {
                    val userId: String? = call.argument("userId")
                    Analytics.setUserId(userId)
                }
                "setUserEmail" -> {
                    val userEmail: String? = call.argument("userEmail")
                    Analytics.setUserEmail(userEmail)
                }
                "generateTestEvent" -> Analytics.generateTestEvent()
                "clearToken" -> Analytics.clearToken()
                "trackEvent" -> {
                    val eventTitle: String = call.argument("eventTitle")!!
                    val data: Map<String, String>? = call.argument("data")
                    if(data != null) {
                        Analytics.trackEvent(eventTitle, data)
                    }else {
                        Analytics.trackEvent(eventTitle, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }

}