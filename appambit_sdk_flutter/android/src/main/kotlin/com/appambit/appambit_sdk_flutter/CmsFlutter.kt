package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.Cms
import com.appambit.sdk.services.interfaces.ICmsQuery
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class CmsFlutter {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, context: Context) {
        this.context = context
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/cms")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "clearCache" -> {
                    val contentType = call.argument<String>("contentType")
                    if (contentType != null) {
                        Cms.clearCache(contentType)
                    }
                    result.success(null)
                }
                "clearAllCache" -> {
                    Cms.clearAllCache()
                    result.success(null)
                }
                "getList" -> {
                    val contentType = call.argument<String>("contentType")
                    if (contentType == null) {
                        result.error("BAD_ARGS", "Missing 'contentType'", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val query = Cms.content(contentType, Any::class.java)
                        
                        val page = call.argument<Int>("page")
                        if (page != null) query.getPage(page)
                        
                        val perPage = call.argument<Int>("perPage")
                        if (perPage != null) query.getPerPage(perPage)
                        
                        val orderBy = call.argument<String>("orderBy")
                        if (orderBy != null) {
                            val orderDir = call.argument<String>("orderDir")
                            if (orderDir == "desc") {
                                query.orderByDescending(orderBy)
                            } else {
                                query.orderByAscending(orderBy)
                            }
                        }

                        val filters = call.argument<List<Map<String, Any>>>("filters")
                        if (filters != null) {
                            for (filter in filters) {
                                val type = filter["type"] as? String ?: continue
                                val field = filter["field"] as? String ?: continue
                                val valueStr = filter["value"]?.toString()
                                val valueNum = filter["value"] as? Number
                                val valueList = filter["value"] as? List<String>

                                when (type) {
                                    "search" -> {
                                        val q = filter["query"] as? String ?: continue
                                        query.search(q)
                                    }
                                    "equals" -> if (valueStr != null) query.equals(field, valueStr)
                                    "notEquals" -> if (valueStr != null) query.notEquals(field, valueStr)
                                    "contains" -> if (valueStr != null) query.contains(field, valueStr)
                                    "startsWith" -> if (valueStr != null) query.startsWith(field, valueStr)
                                    "greaterThan" -> if (valueNum != null) query.greaterThan(field, valueNum)
                                    "greaterThanOrEqual" -> if (valueNum != null) query.greaterThanOrEqual(field, valueNum)
                                    "lessThan" -> if (valueNum != null) query.lessThan(field, valueNum)
                                    "lessThanOrEqual" -> if (valueNum != null) query.lessThanOrEqual(field, valueNum)
                                    "inList" -> if (valueList != null) query.inList(field, valueList)
                                    "notInList" -> if (valueList != null) query.notInList(field, valueList)
                                }
                            }
                        }

                        // We execute getList in a background thread if it throws or takes time, 
                        // but getList itself is mostly fast or spawns its own futures.
                        // Actually getList throws Exception if it fails syncing initially so we wrap it.
                        val queryResult = query.getList()
                        queryResult.then { list ->
                            // Map List<JSONObject> to List<Map<String, Any>>
                            val resultList = mutableListOf<Map<String, Any?>>()
                            for (json in list) {
                                resultList.add(jsonToMap(json as JSONObject))
                            }
                            result.success(resultList)
                        }

                    } catch (e: Exception) {
                        result.error("CMS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        if (::channel.isInitialized) {
            channel.setMethodCallHandler(null)
        }
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = json.get(key)
            if (value === JSONObject.NULL) {
                value = null
            } else if (value is JSONObject) {
                value = jsonToMap(value)
            } else if (value is JSONArray) {
                value = jsonArrayToList(value)
            }
            map[key] = value
        }
        return map
    }

    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        val list = mutableListOf<Any?>()
        for (i in 0 until array.length()) {
            var value = array.get(i)
            if (value === JSONObject.NULL) {
                value = null
            } else if (value is JSONObject) {
                value = jsonToMap(value)
            } else if (value is JSONArray) {
                value = jsonArrayToList(value)
            }
            list.add(value)
        }
        return list
    }
}
