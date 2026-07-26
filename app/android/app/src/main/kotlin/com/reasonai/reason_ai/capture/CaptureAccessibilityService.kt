package com.reasonai.reason_ai.capture

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.view.Display
import android.view.accessibility.AccessibilityEvent

/**
 * Minimal AccessibilityService whose only real job is calling
 * takeScreenshot() (API 30+): once the user enables this service once in
 * system Settings > Accessibility, it lets us grab the screen on demand
 * with no per-capture consent dialog and no persistent "recording"
 * indicator — unlike MediaProjection, which the app used before this
 * rework. We don't declare canRetrieveWindowContent and don't act on any
 * accessibility events; the service exists purely to hold the
 * takeScreenshot capability.
 */
class CaptureAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    /** Grabs exactly one frame as a software bitmap, or null on failure. */
    fun takeScreenshotBitmap(onResult: (Bitmap?) -> Unit) {
        takeScreenshot(
            Display.DEFAULT_DISPLAY,
            mainExecutor,
            object : TakeScreenshotCallback {
                override fun onSuccess(screenshot: ScreenshotResult) {
                    // Hardware bitmaps can't be compressed/cropped directly
                    // (Bitmap.compress and some Bitmap.createBitmap paths
                    // reject Config.HARDWARE) — copy to software once here so
                    // the rest of the pipeline never has to think about it.
                    val hardwareBitmap = screenshot.hardwareBuffer.use { buffer ->
                        Bitmap.wrapHardwareBuffer(buffer, screenshot.colorSpace)
                    }
                    onResult(hardwareBitmap?.copy(Bitmap.Config.ARGB_8888, false))
                }

                override fun onFailure(errorCode: Int) {
                    onResult(null)
                }
            },
        )
    }

    companion object {
        var instance: CaptureAccessibilityService? = null
            private set
    }
}
