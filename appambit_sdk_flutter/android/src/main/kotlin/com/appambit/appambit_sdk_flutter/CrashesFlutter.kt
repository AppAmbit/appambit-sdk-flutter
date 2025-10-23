package com.appambit.appambit_sdk_flutter

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.appambit.sdk.Crashes
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class CrashesFlutter {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/crashes")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "didCrashInLastSession" -> {
                    val didCrash = Crashes.didCrashInLastSession()
                    result.success(didCrash)
                }
                "generateTestCrash" -> {
                    result.success(null)
                    Handler(Looper.getMainLooper()).post {
                        Crashes.generateTestCrash()
                    }
                }
                "logErrorMessage" -> {
                    val args = (call.arguments as? Map<*, *>) ?: emptyMap<Any, Any>()
                    val message = args["message"] as? String
                    val propertiesIn = args["properties"] as? Map<*, *>
                    val props = asStringMap(propertiesIn)
                    if (message == null) {
                        result.error("NO_MESSAGE", "Message null", null)
                    } else {
                        Crashes.logError(message, props.ifEmpty { null })
                        result.success(null)
                    }
                }
                "logError" -> {
                    val args = (call.arguments as? Map<*, *>) ?: emptyMap<Any, Any>()
                    val msg = (args["message"] as? String) ?: (args["errorMessage"] as? String) ?: "UnknownException"
                    val stack = args["stackTrace"] as? String
                    val classFqn = args["classFqn"] as? String
                    val fileName = args["fileName"] as? String
                    val lineNumber = anyToLong(args["lineNumber"])
                    val propertiesIn = args["properties"] as? Map<*, *>
                    val props = asStringMap(propertiesIn)

                    val ex = Exception(msg)
                    val frames = mutableListOf<StackTraceElement>()
                    if (classFqn != null || fileName != null || lineNumber != null) {
                        val cls = classFqn ?: "flutter"
                        val file = lastSegment(fileName ?: "unknown.dart")
                        val line = lineNumber?.toInt() ?: -1
                        frames.add(StackTraceElement(cls, "call", file, line))
                    }
                    if (!stack.isNullOrEmpty()) {
                        frames.addAll(parseDartStack(stack))
                    }
                    if (frames.isEmpty()) {
                        frames.add(StackTraceElement("flutter", "call", "unknown.dart", -1))
                    }
                    ex.stackTrace = frames.toTypedArray()

                    Crashes.logError(ex, props.ifEmpty { null })
                    result.success(null)
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

    private fun anyToLong(any: Any?): Long? = when (any) {
        is Long -> any
        is Int -> any.toLong()
        is Number -> any.toLong()
        is String -> any.toLongOrNull()
        else -> null
    }

    private fun parseDartStack(stack: String): List<StackTraceElement> {
        val lines = stack.split('\n')
        val elems = mutableListOf<StackTraceElement>()
        val regex = Regex("^#\\d+\\s+([^\\s]+)\\s+\\((.+?):(\\d+)(?::(\\d+))?\\)$")
        for (raw in lines) {
            val line = raw.trim()
            if (line.isEmpty()) continue
            val m = regex.find(line) ?: continue
            val symbol = m.groupValues[1]
            val loc = m.groupValues[2]
            val ln = m.groupValues[3].toIntOrNull() ?: -1
            val className = symbol.substringBefore('.', symbol)
            val method = if (symbol.contains('.')) symbol.substringAfter('.') else symbol
            val file = lastSegment(normalizePath(loc))
            elems.add(StackTraceElement(className, method, file, ln))
        }
        return elems
    }

    private fun normalizePath(loc: String): String {
        return if (loc.startsWith("file:")) kotlin.runCatching { java.net.URI(loc).path ?: loc }.getOrDefault(loc) else loc
    }

    private fun lastSegment(path: String): String {
        val p = path.replace('\\', '/')
        val idx = p.lastIndexOf('/')
        return if (idx >= 0) p.substring(idx + 1) else p
    }
}