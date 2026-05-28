package com.example.appambit_sdk_push_notifications

import com.appambit.sdk.models.AppAmbitNotification

internal object PushPayloadMapper {

    /// Maps `AppAmbitNotification` into the shape consumed by Dart's
    /// `PushNotificationData.fromMap`. Mirrors the iOS plugin's payload shape.
    fun payloadOf(n: AppAmbitNotification): Map<String, Any?> {
        val data = HashMap<String, String>()
        for ((k, v) in n.data) data[k] = v ?: ""

        val android = HashMap<String, Any?>()
        n.color?.let { android["color"] = it }
        n.smallIconName?.let { android["smallIconName"] = it }
        n.ticker?.let { android["ticker"] = it }
        n.sticky?.let { android["sticky"] = it }
        n.visibility?.let { android["visibility"] = it }
        n.channelId?.let { android["channelId"] = it }
        n.priority?.let { android["priority"] = it }
        n.tag?.let { android["tag"] = it }
        n.sound?.let { android["sound"] = it }
        n.clickAction?.let { android["clickAction"] = it }

        val payload = HashMap<String, Any?>()
        n.title?.let { payload["title"] = it }
        n.body?.let { payload["body"] = it }
        n.imageUrl?.let { payload["imageUrl"] = it }
        if (data.isNotEmpty()) payload["data"] = data
        if (android.isNotEmpty()) payload["android"] = android
        return payload
    }
}
