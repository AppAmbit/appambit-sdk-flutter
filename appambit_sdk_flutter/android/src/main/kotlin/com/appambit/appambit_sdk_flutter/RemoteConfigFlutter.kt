package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.RemoteConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class RemoteConfigFlutter {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/remoteconfig")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    val enabled = RemoteConfig.enable()
                    result.success(enabled)
                }
                "getString" -> {
                    val args = call.arguments as? Map<*, *>
                    val key = args?.get("key") as? String
                    if (key == null) {
                        result.error("BAD_ARGS", "Missing 'key'", null)
                    } else {
                        val value = RemoteConfig.getString(key)
                        result.success(value)
                    }
                }
                "getBoolean" -> {
                    val args = call.arguments as? Map<*, *>
                    val key = args?.get("key") as? String
                    if (key == null) {
                        result.error("BAD_ARGS", "Missing 'key'", null)
                    } else {
                        val value = RemoteConfig.getBoolean(key)
                        result.success(value)
                    }
                }
                "getInt" -> {
                    val args = call.arguments as? Map<*, *>
                    val key = args?.get("key") as? String
                    if (key == null) {
                        result.error("BAD_ARGS", "Missing 'key'", null)
                    } else {
                        val value = RemoteConfig.getInt(key)
                        result.success(value)
                    }
                }
                "getDouble" -> {
                    val args = call.arguments as? Map<*, *>
                    val key = args?.get("key") as? String
                    if (key == null) {
                        result.error("BAD_ARGS", "Missing 'key'", null)
                    } else {
                        val value = RemoteConfig.getDouble(key)
                        result.success(value)
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
