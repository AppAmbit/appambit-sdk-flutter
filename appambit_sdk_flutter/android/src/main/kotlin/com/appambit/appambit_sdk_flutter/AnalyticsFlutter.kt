package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.Analytics
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class AnalyticsFlutter {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/analytics")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableManualSession" -> {
                    Analytics.enableManualSession()
                    result.success(null)
                }
                "startSession" -> {
                    Analytics.startSession()
                    result.success(null)
                }
                "endSession" -> {
                    Analytics.endSession()
                    result.success(null)
                }
                "setUserId" -> {
                    val args = call.arguments as? Map<*, *>
                    val userId = args?.get("userId") as? String
                    Analytics.setUserId(userId)
                    result.success(null)
                }
                "setEmail" -> {
                    val args = call.arguments as? Map<*, *>
                    val email = (args?.get("email") as? String) ?: (args?.get("userEmail") as? String)
                    if (email != null) {
                        Analytics.setUserEmail(email)
                    }
                    result.success(null)
                }
                "generateTestEvent" -> {
                    Analytics.generateTestEvent()
                    result.success(null)
                }
                "clearToken" -> {
                    Analytics.clearToken()
                    result.success(null)
                }
                "trackEvent" -> {
                    val args = call.arguments as? Map<*, *>
                    val name = (args?.get("name") as? String) ?: (args?.get("eventTitle") as? String)
                    val props = asStringMap((args?.get("properties") as? Map<*, *>) ?: (args?.get("data") as? Map<*, *>))
                    if (name != null) {
                        if (props.isNotEmpty()) {
                            Analytics.trackEvent(name, props)
                        } else {
                            Analytics.trackEvent(name, null)
                        }
                        result.success(null)
                    } else {
                        result.notImplemented()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }

    private fun asStringMap(map: Map<*, *>?): Map<String, String> {
        if (map == null) return emptyMap()
        val out = mutableMapOf<String, String>()
        for ((k, v) in map) {
            val key = k as? String ?: continue
            val value = v?.toString() ?: continue
            out[key] = value
        }
        return out
    }
}
