package com.reasonai.reason_ai.overlay

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Dart `OverlayBridge` to the native overlay permission +
 * service. Kept separate from [com.reasonai.reason_ai.MainActivity] so the
 * activity doesn't accumulate feature-specific logic as more channels
 * (e.g. screen capture in Milestone 3) are added.
 */
class OverlayMethodChannelHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(activity))

            "requestOverlayPermission" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}"),
                )
                activity.startActivity(intent)
                result.success(null)
            }

            "startOverlay" -> {
                if (Settings.canDrawOverlays(activity)) {
                    OverlayService.start(activity.applicationContext)
                    result.success(true)
                } else {
                    result.success(false)
                }
            }

            "stopOverlay" -> {
                OverlayService.stop(activity.applicationContext)
                result.success(null)
            }

            "isOverlayRunning" -> result.success(OverlayService.isRunning)

            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.reasonai.reason_ai/overlay"
    }
}
