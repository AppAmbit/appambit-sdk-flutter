package com.appambit.appambit_sdk_flutter

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Settles review comment #11 ("Android detach() replies over a disconnected
 * channel; tolerated, but logs warnings"): does calling MethodChannel.Result
 * on a Result captured *before* setMethodCallHandler(null) fail, warn, or
 * get dropped once the handler has been cleared? That's exactly what
 * CloudCodeFlutter.detach() -> cancelPending() does to every still-pending
 * request.
 *
 * Decompiling MethodChannel$IncomingMethodCallHandler$1 (the real Result
 * implementation the Flutter engine hands to every MethodCallHandler) shows
 * error()/success() go straight from `codec.encodeErrorEnvelope(...)` to
 * the BinaryReply captured at dispatch time - they never look at the
 * channel's currently registered handler. So this is pure io.flutter.plugin
 * .common wiring with zero Android framework / Looper involvement, and can
 * be exercised end-to-end (real MethodChannel, real codec, a fake
 * BinaryMessenger standing in for the engine) in a plain JVM test.
 */
internal class CloudCodeFlutterChannelReplyTest {

    private class FakeBinaryMessenger : BinaryMessenger {
        val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()

        override fun send(channel: String, message: ByteBuffer?) {}

        override fun send(
            channel: String,
            message: ByteBuffer?,
            callback: BinaryMessenger.BinaryReply?,
        ) {
        }

        override fun setMessageHandler(
            channel: String,
            handler: BinaryMessenger.BinaryMessageHandler?,
        ) {
            handlers[channel] = handler
        }
    }

    @Test
    fun replyingAfterSetMethodCallHandlerNull_stillDeliversTheReply() {
        val messenger = FakeBinaryMessenger()
        val channel = MethodChannel(messenger, "com.appambit/cloudcode")

        var capturedResult: MethodChannel.Result? = null
        channel.setMethodCallHandler { _, result -> capturedResult = result }

        val encodedCall = StandardMethodCodec.INSTANCE.encodeMethodCall(
            MethodCall("call", mapOf("requestId" to "r1", "function" to "demo")),
        )
        // encodeMethodCall returns the buffer positioned at its write cursor;
        // decode expects it positioned at 0, exactly like the engine's own
        // dispatch code does before invoking a BinaryMessageHandler.
        encodedCall.flip()

        var replyInvoked = false
        var replyBuffer: ByteBuffer? = null
        messenger.handlers.getValue("com.appambit/cloudcode")!!.onMessage(encodedCall) { reply ->
            replyInvoked = true
            replyBuffer = reply
        }

        val result = assertNotNull(capturedResult, "handler should have received a Result")
        assertFalse(replyInvoked, "no reply should be sent until the handler actually replies")

        // The exact sequence CloudCodeFlutter.detach() -> cancelPending() performs:
        // null the channel's handler, THEN reply on a Result captured earlier.
        channel.setMethodCallHandler(null)

        result.error(
            "CLOUD_CODE_ERROR",
            "Cloud Code request was cancelled",
            mapOf("code" to "CANCELLED"),
        )

        assertTrue(
            replyInvoked,
            "Result.error() must still deliver a reply after setMethodCallHandler(null) - " +
                "it holds its own BinaryReply callback from dispatch time and never " +
                "consults the channel's current handler registration.",
        )
        assertNotNull(replyBuffer)
    }
}
