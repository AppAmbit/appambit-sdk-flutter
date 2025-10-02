package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.Crashes
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.collections.set

class CrashesFlutter {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/crashes")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "didCrashInLastSession" -> {
                    Crashes.didCrashInLastSession()
                    result.success(null)
                }
                "generateTestCrash" -> {
                    Crashes.generateTestCrash()
                    result.success(null)
                }
                "logError" -> {
                    val exceptionMap: Map<String, String>? = call.argument("exception")
                    val properties: Map<String, String> = call.argument<Map<String, String>>("properties") ?: emptyMap()

                    if (exceptionMap != null) {
                        val type = exceptionMap["type"]
                        val message = exceptionMap["message"]
                        val stackTrace = exceptionMap["stackTrace"]

                        val ex = Exception("$type: $message\n$stackTrace")

                        if (properties.isNotEmpty()) {
                            Crashes.logError(ex, properties)
                        } else {
                            Crashes.logError(ex)
                        }
                    } else {
                        Crashes.logError(Exception("UnknownException"), properties)
                    }

                    result.success(null)
                }

                "logErrorMessage" -> {
                    val message = call.argument<String>("message")
                    val properties: Map<String, String>? = call.argument("properties")

                    if (message == null) {
                        result.error("NO_MESSAGE", "Message null", null)
                        return@setMethodCallHandler
                    }

                    if (properties != null && properties.isNotEmpty()) {
                        Crashes.logError(message, properties)
                    } else {
                        Crashes.logError(message)
                    }

                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }
}