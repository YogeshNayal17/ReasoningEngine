package com.reasonai.reason_ai.capture

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Takes plain function references rather than an Activity/Context directly
 * — the MediaProjection consent flow needs `startActivityForResult`, which
 * only [com.reasonai.reason_ai.MainActivity] can drive, but this handler
 * doesn't need to know that concrete type to stay decoupled from it.
 */
class CaptureMethodChannelHandler(
    private val hasPermission: () -> Boolean,
    private val requestPermission: (MethodChannel.Result) -> Unit,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasPermission())
            "requestPermission" -> requestPermission(result)
            "consumePendingCapture" -> result.success(PendingCaptureStore.consume())
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.reasonai.reason_ai/capture"
    }
}
