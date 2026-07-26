package com.reasonai.reason_ai.capture

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import com.reasonai.reason_ai.R
import java.io.ByteArrayOutputStream

/**
 * Foreground service that owns the [MediaProjection] granted once by the
 * user and reuses it for every subsequent capture, so tapping the bubble
 * repeatedly doesn't re-prompt for permission. A [VirtualDisplay] and
 * [ImageReader] are created fresh per capture and torn down immediately
 * after grabbing one frame — there's no continuous recording, just
 * on-demand single screenshots.
 */
class ScreenCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var isCapturing = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            // Fires if the user revokes via the system "Stop" action.
            mediaProjection = null
            isActive = false
            instance = null
            stopSelf()
        }
    }

    override fun onCreate() {
        super.onCreate()
        // Must start as foreground with the mediaProjection type before
        // getMediaProjection() is called (required on API 34+).
        startAsForeground()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        val data = intent?.let { IntentCompat.getParcelableExtra(it, EXTRA_DATA, Intent::class.java) }
        if (data != null) {
            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val projection = manager.getMediaProjection(resultCode, data)
            if (projection != null) {
                projection.registerCallback(projectionCallback, Handler(Looper.getMainLooper()))
                mediaProjection = projection
                isActive = true
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mediaProjection?.unregisterCallback(projectionCallback)
        mediaProjection?.stop()
        mediaProjection = null
        isActive = false
        instance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Grabs exactly one frame and returns it as PNG bytes, or null on failure. */
    fun captureOnce(onResult: (ByteArray?) -> Unit) {
        val projection = mediaProjection
        if (projection == null || isCapturing) {
            onResult(null)
            return
        }
        isCapturing = true

        val metrics = resources.displayMetrics
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        var virtualDisplay: VirtualDisplay? = null

        imageReader.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            val bytes = image?.let { toPngBytes(it, width, height) }
            image?.close()
            virtualDisplay?.release()
            reader.close()
            isCapturing = false
            onResult(bytes)
        }, Handler(Looper.getMainLooper()))

        virtualDisplay = projection.createVirtualDisplay(
            "ReasonAiCapture",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.surface,
            null,
            null,
        )
    }

    private fun toPngBytes(image: Image, width: Int, height: Int): ByteArray {
        // RGBA_8888 rows can be padded to a stride wider than width * 4;
        // crop that padding out before encoding.
        val plane = image.planes[0]
        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        val rowPadding = rowStride - pixelStride * width

        val rawBitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888,
        )
        rawBitmap.copyPixelsFromBuffer(plane.buffer)
        val bitmap = if (rowPadding == 0) rawBitmap else Bitmap.createBitmap(rawBitmap, 0, 0, width, height)

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        if (bitmap !== rawBitmap) rawBitmap.recycle()
        bitmap.recycle()
        return stream.toByteArray()
    }

    private fun startAsForeground() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reason AI screen capture",
            NotificationManager.IMPORTANCE_LOW,
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Reason AI can capture your screen")
            .setContentText("Tap the floating bubble to capture and analyze a claim.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val CHANNEL_ID = "reason_ai_capture"
        private const val NOTIFICATION_ID = 43
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"

        var isActive: Boolean = false
            private set

        var instance: ScreenCaptureService? = null
            private set

        fun start(context: Context, resultCode: Int, data: Intent) {
            val intent = Intent(context, ScreenCaptureService::class.java)
                .putExtra(EXTRA_RESULT_CODE, resultCode)
                .putExtra(EXTRA_DATA, data)
            ContextCompat.startForegroundService(context, intent)
        }
    }
}
