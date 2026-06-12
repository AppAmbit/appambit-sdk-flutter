package com.appambit.appambit_sdk_flutter

import android.content.Context
import com.appambit.sdk.AppAmbitDb
import com.appambit.sdk.models.db.DbResult
import com.appambit.sdk.models.db.DbStatement
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class DatabaseFlutter {

    private lateinit var channel: MethodChannel

    fun attach(binding: FlutterPlugin.FlutterPluginBinding, @Suppress("UNUSED_PARAMETER") context: Context) {
        channel = MethodChannel(binding.binaryMessenger, "com.appambit/db")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "execute" -> {
                    val args = call.arguments as? Map<*, *>
                    val sql = args?.get("sql") as? String
                    if (sql == null) {
                        result.error("BAD_ARGS", "Missing 'sql'", null)
                        return@setMethodCallHandler
                    }
                    @Suppress("UNCHECKED_CAST")
                    val params = args["params"] as? List<Any?>

                    try {
                        val future = if (params != null && params.isNotEmpty()) {
                            AppAmbitDb.execute(sql, *params.toTypedArray())
                        } else {
                            AppAmbitDb.execute(sql)
                        }
                        future.then { dbResult ->
                            result.success(dbResultToMap(dbResult))
                        }
                        future.onError { e ->
                            result.success(errorMap(e.message ?: "Unknown error"))
                        }
                    } catch (e: Exception) {
                        result.success(errorMap(e.message ?: "Unknown error"))
                    }
                }

                "batch" -> {
                    val args = call.arguments as? Map<*, *>
                    @Suppress("UNCHECKED_CAST")
                    val statementsRaw = args?.get("statements") as? List<Map<String, Any?>>
                    val inTransaction = (args?.get("inTransaction") as? Boolean) ?: false

                    if (statementsRaw == null) {
                        result.error("BAD_ARGS", "Missing 'statements'", null)
                        return@setMethodCallHandler
                    }

                    val statements = statementsRaw.map { s ->
                        val stSql = s["sql"] as? String ?: ""
                        @Suppress("UNCHECKED_CAST")
                        val stParams = s["params"] as? List<Any?>
                        if (stParams != null && stParams.isNotEmpty()) {
                            DbStatement.of(stSql, *stParams.toTypedArray())
                        } else {
                            DbStatement.of(stSql)
                        }
                    }.toTypedArray()

                    try {
                        val future = if (inTransaction) {
                            AppAmbitDb.batchInTransaction(*statements)
                        } else {
                            AppAmbitDb.batch(*statements)
                        }
                        future.then { results ->
                            result.success(results.map { r -> dbResultToMap(r) })
                        }
                        future.onError { e ->
                            result.success(listOf(errorMap(e.message ?: "Unknown error")))
                        }
                    } catch (e: Exception) {
                        result.success(listOf(errorMap(e.message ?: "Unknown error")))
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

    private fun dbResultToMap(r: DbResult): Map<String, Any?> = mapOf(
        "columns" to r.columns,
        "rows" to r.rows,
        "rowsRead" to r.rowsRead,
        "rowsWritten" to r.rowsWritten,
        "error" to if (r.hasError()) r.error else null,
    )

    private fun errorMap(msg: String): Map<String, Any?> = mapOf(
        "columns" to emptyList<String>(),
        "rows" to emptyList<List<Any?>>(),
        "rowsRead" to 0,
        "rowsWritten" to 0,
        "error" to msg,
    )
}
