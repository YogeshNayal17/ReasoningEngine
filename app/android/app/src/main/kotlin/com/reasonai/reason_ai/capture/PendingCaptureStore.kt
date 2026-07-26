package com.reasonai.reason_ai.capture

/**
 * Holds the most recently captured screenshot until Flutter picks it up.
 * The capture is triggered from the overlay bubble (a Service), which has
 * no direct line to a running Dart isolate — the app is brought to the
 * foreground instead, and `CaptureController` on the Dart side pulls this
 * on resume, mirroring how it already re-checks overlay permission there.
 */
object PendingCaptureStore {
    @Volatile
    private var bytes: ByteArray? = null

    fun put(value: ByteArray) {
        bytes = value
    }

    fun consume(): ByteArray? {
        val value = bytes
        bytes = null
        return value
    }
}
