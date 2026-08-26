package com.appambit.appambit_sdk_flutter

import com.appambit.sdk.enums.CloudCodeHttpMethod
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Regression coverage for the CloudCodeFlutter <-> native SDK bridge.
 *
 * parseMethod is private; it's exercised through reflection so the test
 * fails loudly if the bridge ever goes back to the SDK's other HTTP-method
 * enum (com.appambit.sdk.enums.HttpMethodEnum), which CloudCode.call in
 * appambit:1.2.0 does not accept (compile-time mismatch, not runtime).
 */
internal class CloudCodeFlutterTest {

    private fun parseMethod(value: String?): CloudCodeHttpMethod? {
        val method = CloudCodeFlutter::class.java.getDeclaredMethod(
            "parseMethod",
            String::class.java,
        )
        method.isAccessible = true
        val bridge = CloudCodeFlutter()
        @Suppress("UNCHECKED_CAST")
        return method.invoke(bridge, value) as CloudCodeHttpMethod?
    }

    @Test
    fun parseMethod_resolvesToNativeCloudCodeHttpMethod_notHttpMethodEnum() {
        val resolved = parseMethod("post")
        assertTrue(
            resolved is CloudCodeHttpMethod,
            "parseMethod must return com.appambit.sdk.enums.CloudCodeHttpMethod " +
                "(the type CloudCode.call in appambit:1.2.0 actually accepts), " +
                "not HttpMethodEnum.",
        )
        assertEquals(CloudCodeHttpMethod.POST, resolved)
    }

    @Test
    fun parseMethod_isCaseInsensitiveForAllFiveVerbs() {
        assertEquals(CloudCodeHttpMethod.GET, parseMethod("get"))
        assertEquals(CloudCodeHttpMethod.POST, parseMethod("Post"))
        assertEquals(CloudCodeHttpMethod.PUT, parseMethod("PUT"))
        assertEquals(CloudCodeHttpMethod.DELETE, parseMethod("delete"))
        assertEquals(CloudCodeHttpMethod.PATCH, parseMethod("pAtCh"))
    }

    @Test
    fun parseMethod_returnsNullForUnknownOrMissingValue() {
        assertNull(parseMethod("TRACE"))
        assertNull(parseMethod(null))
        assertNull(parseMethod(""))
    }

    @Test
    fun call_missingRequestId_repliesBadArgsWithoutTouchingNativeSdk() {
        val bridge = CloudCodeFlutter()
        val call = MethodCall("call", mapOf("function" to "demo"))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        bridge.handleForTest(call, mockResult)

        Mockito.verify(mockResult).error("BAD_ARGS", "Missing 'requestId'", null)
    }

    @Test
    fun cancel_missingRequestId_repliesBadArgs() {
        val bridge = CloudCodeFlutter()
        val call = MethodCall("cancel", emptyMap<String, Any>())
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        bridge.handleForTest(call, mockResult)

        Mockito.verify(mockResult).error("BAD_ARGS", "Missing 'requestId'", null)
    }
}

/** Test-only reflection helpers so we don't have to widen CloudCodeFlutter's visibility. */
private fun CloudCodeFlutter.handleForTest(call: MethodCall, result: MethodChannel.Result) {
    val method = CloudCodeFlutter::class.java.getDeclaredMethod(
        "handle",
        MethodCall::class.java,
        MethodChannel.Result::class.java,
    )
    method.isAccessible = true
    method.invoke(this, call, result)
}
