package com.reasonai.reason_ai

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.reasonai.reason_ai.capture.CaptureMethodChannelHandler
import com.reasonai.reason_ai.capture.ScreenCaptureService
import com.reasonai.reason_ai.overlay.OverlayMethodChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val mediaProjectionManager by lazy {
        getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    }

    private var pendingCaptureResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OverlayMethodChannelHandler.CHANNEL)
            .setMethodCallHandler(OverlayMethodChannelHandler(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CaptureMethodChannelHandler.CHANNEL)
            .setMethodCallHandler(
                CaptureMethodChannelHandler(
                    hasPermission = { ScreenCaptureService.isActive },
                    requestPermission = ::requestCapturePermission,
                ),
            )
    }

    // FlutterActivity extends the plain (non-AndroidX) Activity class, so the
    // modern registerForActivityResult API isn't available here — this is
    // the classic startActivityForResult/onActivityResult pattern instead,
    // which Flutter's embedding explicitly supports overriding.
    private fun requestCapturePermission(result: MethodChannel.Result) {
        pendingCaptureResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), CAPTURE_PERMISSION_REQUEST_CODE)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CAPTURE_PERMISSION_REQUEST_CODE) return

        val granted = resultCode == Activity.RESULT_OK && data != null
        if (granted) {
            ScreenCaptureService.start(applicationContext, resultCode, data!!)
        }
        pendingCaptureResult?.success(granted)
        pendingCaptureResult = null
    }

    // The foreground service notification needs POST_NOTIFICATIONS on API 33+;
    // requested once eagerly on launch rather than gated behind a dedicated
    // flow, since a denial only degrades to "no notification shown" — the
    // overlay itself still works.
    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val permission = Manifest.permission.POST_NOTIFICATIONS
        if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(permission), NOTIFICATION_PERMISSION_REQUEST_CODE)
        }
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
        private const val CAPTURE_PERMISSION_REQUEST_CODE = 2001
    }
}
