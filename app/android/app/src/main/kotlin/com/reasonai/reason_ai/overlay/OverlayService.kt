package com.reasonai.reason_ai.overlay

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
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
 * [isRunning] is a simple static flag rather than a bound-service query:
 * the only consumer is [OverlayMethodChannelHandler] running in the same
 * process, so binding would add ceremony without adding safety.
 */
class OverlayService : Service() {

    private var bubbleController: OverlayBubbleController? = null

    override fun onCreate() {
        super.onCreate()
        startAsForeground()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
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
        captureService.captureOnce { bytes ->
            if (bytes != null) {
                PendingCaptureStore.put(bytes)
            }
            bringAppToForeground()
        }
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
