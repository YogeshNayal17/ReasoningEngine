package com.reasonai.reason_ai.capture

/**
 * Mirrors [PendingCaptureStore], but for the "from clipboard/text"
 * bubble-menu option: there's no bytes to hand off, just a flag telling
 * Flutter to read the clipboard itself once it's back in the foreground.
 * That has to happen from Dart, not here — Android 10+ only lets the
 * focused app read clipboard contents, and this store is written from a
 * background Service.
 */
object PendingClipboardRequestStore {
    @Volatile
    private var requested = false

    fun request() {
        requested = true
    }

    fun consume(): Boolean {
        val value = requested
        requested = false
        return value
    }
}
