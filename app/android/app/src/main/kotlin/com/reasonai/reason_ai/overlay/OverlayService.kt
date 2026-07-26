package com.reasonai.reason_ai.overlay

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.reasonai.reason_ai.MainActivity
import com.reasonai.reason_ai.R
import com.reasonai.reason_ai.capture.PendingCaptureStore
import com.reasonai.reason_ai.capture.ScreenCaptureService

/**
 * Foreground service that owns the overlay bubble's window for as long as
 * it's showing. A foreground service (rather than an Activity-scoped view)
 * is what makes the bubble survive the host app being backgrounded — its
 * lifecycle is independent of [com.reasonai.reason_ai.MainActivity].
 *
 * Also owns the full-screen [SelectionOverlayController] shown right after
 * a capture: the user drags a selection and confirms/cancels entirely as
 * an overlay, without the app ever coming to the foreground. Only a
 * confirmed selection brings [MainActivity] forward — that's where OCR
 * needs to run and, eventually, where the reasoning UI lives.
 *
 * [isRunning] is a simple static flag rather than a bound-service query:
 * the only consumer is [OverlayMethodChannelHandler] running in the same
 * process, so binding would add ceremony without adding safety.
 */
class OverlayService : Service() {

    private var bubbleController: OverlayBubbleController? = null
    private var selectionOverlayController: SelectionOverlayController? = null
    private lateinit var windowManager: WindowManager

    override fun onCreate() {
        super.onCreate()
        startAsForeground()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        bubbleController = OverlayBubbleController(
            context = this,
            windowManager = windowManager,
            onCloseRequested = ::stopSelf,
            onCaptureRequested = ::handleCaptureRequested,
        )
        bubbleController?.attach()
        isRunning = true
    }

    override fun onDestroy() {
        selectionOverlayController?.detach()
        selectionOverlayController = null
        bubbleController?.detach()
        bubbleController = null
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun handleCaptureRequested() {
        val captureService = ScreenCaptureService.instance
        if (captureService == null) {
            // No screen-capture permission granted yet — surface the app
            // so the user can grant it, rather than silently doing nothing.
            bringAppToForeground()
            return
        }
        // Hide the bubble first — it's a window like any other, so it would
        // otherwise show up in its own screenshot. The short delay gives the
        // visibility change a frame to actually composite before capturing.
        bubbleController?.setVisible(false)
        Handler(Looper.getMainLooper()).postDelayed({
            captureService.captureOnce { bytes ->
                bubbleController?.setVisible(true)
                if (bytes != null) {
                    showSelectionOverlay(bytes)
                }
            }
        }, HIDE_BUBBLE_DELAY_MS)
    }

    private fun showSelectionOverlay(pngBytes: ByteArray) {
        val bitmap = BitmapFactory.decodeByteArray(pngBytes, 0, pngBytes.size) ?: return
        selectionOverlayController = SelectionOverlayController(
            context = this,
            windowManager = windowManager,
            bitmap = bitmap,
            onConfirm = { croppedBytes ->
                PendingCaptureStore.put(croppedBytes)
                dismissSelectionOverlay()
                bringAppToForeground()
            },
            onCancel = ::dismissSelectionOverlay,
        )
        selectionOverlayController?.attach()
    }

    private fun dismissSelectionOverlay() {
        selectionOverlayController?.detach()
        selectionOverlayController = null
    }

    private fun bringAppToForeground() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        startActivity(intent)
    }

    private fun startAsForeground() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reason AI overlay",
            NotificationManager.IMPORTANCE_LOW,
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Reason AI is active")
            .setContentText("Tap the floating bubble to analyze a claim.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val CHANNEL_ID = "reason_ai_overlay"
        private const val NOTIFICATION_ID = 42
        private const val HIDE_BUBBLE_DELAY_MS = 50L

        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            ContextCompat.startForegroundService(context, Intent(context, OverlayService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, OverlayService::class.java))
        }
    }
}
