package com.reasonai.reason_ai

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pendingSharedUrl: String? = null
    private var shareChannel: MethodChannel? = null

    companion object {
        private const val SHARE_CHANNEL = "com.reasonai.reason_ai/share"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingSharedUrl = extractSharedUrl(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val url = extractSharedUrl(intent) ?: return
        pendingSharedUrl = url
        // Notify Flutter if the engine is already running
        shareChannel?.invokeMethod("onSharedUrl", url)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumePendingSharedUrl" -> {
                        result.success(pendingSharedUrl)
                        pendingSharedUrl = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun extractSharedUrl(intent: Intent): String? {
        if (intent.action != Intent.ACTION_SEND) return null
        if (intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
