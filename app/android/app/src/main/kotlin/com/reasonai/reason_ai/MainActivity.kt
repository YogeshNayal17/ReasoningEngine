package com.reasonai.reason_ai

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.reasonai.reason_ai.capture.CaptureAccessibilityService
import com.reasonai.reason_ai.capture.CaptureMethodChannelHandler
import com.reasonai.reason_ai.overlay.OverlayMethodChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

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
                    hasPermission = ::hasAccessibilityPermission,
                    requestPermission = ::openAccessibilitySettings,
                ),
            )
    }

    // Unlike MediaProjection's in-app consent dialog, an AccessibilityService
    // can only be enabled/disabled from system Settings — there's no
    // ActivityResult to await here. We check the enabled-services list
    // directly rather than caching a boolean ourselves, since the user can
    // also revoke it from Settings while the app isn't running.
    //
    // Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES stores entries using
    // ComponentName's *shorthand* form for services in the app's own
    // package (e.g. "com.reasonai.reason_ai/.capture.CaptureAccessibilityService"),
    // not the fully-qualified form ComponentName.flattenToString() produces
    // ("com.reasonai.reason_ai/com.reasonai.reason_ai.capture....") — a
    // plain string comparison against the latter always fails even when the
    // service is genuinely enabled. ComponentName.unflattenFromString()
    // understands both forms and normalizes them, so parse each entry with
    // it and compare ComponentNames instead of raw strings.
    private fun hasAccessibilityPermission(): Boolean {
        val expected = ComponentName(this, CaptureAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            ?: return false
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == expected }
    }

    private fun openAccessibilitySettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
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
    }
}
