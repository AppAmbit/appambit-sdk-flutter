package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.AppAmbit
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AppambitSdkFlutterPlugin */
class AppambitSdkFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var crashes: CrashesFlutter
    private lateinit var analytics: AnalyticsFlutter
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.appambit/appambitcore")
        channel.setMethodCallHandler(this)

        crashes = CrashesFlutter()
        crashes.attach(flutterPluginBinding, context)

        analytics = AnalyticsFlutter()
        analytics.attach(flutterPluginBinding, context)

    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "start") {
            val appKey: String = call.argument("appKey")!!
            AppAmbit.start(context, appKey)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        crashes.detach()
        analytics.detach()
    }
}
