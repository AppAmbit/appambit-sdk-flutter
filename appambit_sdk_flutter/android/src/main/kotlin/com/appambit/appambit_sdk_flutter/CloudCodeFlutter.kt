package com.appambit.appambit_sdk_flutter

import com.appambit.sdk.CloudCode
import com.appambit.sdk.enums.CloudCodeHttpMethod
import com.appambit.sdk.models.cloudcode.CloudCodeError
import com.appambit.sdk.models.cloudcode.CloudCodeRequest
import com.appambit.sdk.models.cloudcode.CloudCodeResponse
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class CloudCodeFlutter {
    private lateinit var channel: MethodChannel
    private val requests = ConcurrentHashMap<String, PendingRequest>()

    private class PendingRequest(
        val request: CloudCodeRequest<CloudCodeResponse>,
        val result: MethodChannel.Result,
    )

    fun attach(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/cloudcode")
        channel.setMethodCallHandler(::handle)
    }

    fun detach() {
        if (::channel.isInitialized) {
            channel.setMethodCallHandler(null)
        }
        requests.keys.toList().forEach { requestId -> cancelPending(requestId) }
        requests.clear()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "call" -> call(call, result)
            "cancel" -> cancel(call, result)
            else -> result.notImplemented()
        }
    }

    private fun call(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
        val requestId = args["requestId"] as? String
        if (requestId.isNullOrEmpty()) {
            result.error("BAD_ARGS", "Missing 'requestId'", null)
            return
        }

        val function = args["function"] as? String ?: ""
        val method = parseMethod(args["method"] as? String)
        @Suppress("UNCHECKED_CAST")
        val query = args["query"] as? Map<String, String>
        @Suppress("UNCHECKED_CAST")
        val body = args["body"] as? Map<String, Any>
        @Suppress("UNCHECKED_CAST")
        val headers = args["headers"] as? Map<String, String>

        val request = CloudCode.call(function, method, query, body, headers)
        requests[requestId] = PendingRequest(request, result)
        request.then { response ->
            requests.remove(requestId)?.result?.success(responseToMap(response))
        }
        request.onError { error ->
            requests.remove(requestId)?.result?.error(
                "CLOUD_CODE_ERROR",
                error.message ?: "Cloud Code request failed",
                errorToMap(error),
            )
        }
    }

    private fun cancel(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
        val requestId = args["requestId"] as? String
        if (requestId.isNullOrEmpty()) {
            result.error("BAD_ARGS", "Missing 'requestId'", null)
            return
        }

        cancelPending(requestId)
        result.success(null)
    }

    private fun cancelPending(requestId: String) {
        val pending = requests.remove(requestId) ?: return
        pending.request.cancel()
        pending.result.error("CLOUD_CODE_ERROR", "Cloud Code request was cancelled", mapOf("code" to "CANCELLED"))
    }

    private fun parseMethod(value: String?): CloudCodeHttpMethod? {
        return try {
            CloudCodeHttpMethod.valueOf(value?.uppercase() ?: "")
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun responseToMap(response: CloudCodeResponse): Map<String, Any?> = mapOf(
        "data" to response.data,
        "statusCode" to response.statusCode,
        "requestId" to response.requestId,
        "headers" to response.headers,
    )

    private fun errorToMap(error: Throwable): Map<String, Any?> {
        if (error !is CloudCodeError) {
            return mapOf(
                "code" to "TRANSPORT",
                "message" to (error.message ?: "Cloud Code request failed"),
            )
        }

        return mapOf(
            "code" to error.code.name,
            "message" to (error.message ?: "Cloud Code request failed"),
            "function" to error.function,
            "header" to error.header,
            "statusCode" to if (error.statusCode >= 0) error.statusCode else null,
            "body" to error.body,
            "rawBody" to error.rawBody,
            "requestId" to error.requestId,
        )
    }
}
