package com.reasonai.reason_ai.capture

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Takes plain function references rather than a Context directly, mirroring
 * OverlayMethodChannelHandler, to stay decoupled from MainActivity's
 * concrete type. `requestPermission` is fire-and-forget: enabling an
 * AccessibilityService only happens in system Settings, so there's no grant
 * result to await here — `CaptureController` re-checks `hasPermission` when
 * the app resumes instead.
 */
class CaptureMethodChannelHandler(
    private val hasPermission: () -> Boolean,
    private val requestPermission: () -> Unit,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasPermission())
            "requestPermission" -> {
                requestPermission()
                result.success(hasPermission())
            }
            "consumePendingCapture" -> result.success(PendingCaptureStore.consume())
            "consumePendingClipboardRequest" -> result.success(PendingClipboardRequestStore.consume())
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.reasonai.reason_ai/capture"
    }
}
