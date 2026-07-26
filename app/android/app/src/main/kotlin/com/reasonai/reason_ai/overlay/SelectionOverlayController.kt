package com.reasonai.reason_ai.overlay

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import com.reasonai.reason_ai.R
import java.io.ByteArrayOutputStream

/**
 * Full-screen overlay shown right after a capture: the screenshot with a
 * draggable selection rectangle on top, plus confirm/cancel controls.
 * Unlike the small bubble, this window is focusable/touchable across the
 * whole screen — it needs real drag-gesture input, not just a tap/drag on
 * a small icon.
 */
class SelectionOverlayController(
    context: Context,
    private val windowManager: WindowManager,
    private val bitmap: Bitmap,
    private val onConfirm: (ByteArray) -> Unit,
    private val onCancel: () -> Unit,
) {
    private val canvasView = SelectionCanvasView(context, bitmap)
    private val view: View = LayoutInflater.from(context).inflate(R.layout.selection_overlay, null).apply {
        findViewById<FrameLayout>(R.id.selection_canvas_container).addView(canvasView)
    }
    private val confirmButton = view.findViewById<View>(R.id.selection_confirm)
    private val cancelButton = view.findViewById<View>(R.id.selection_cancel)

    private val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT,
    )

    init {
        confirmButton.visibility = View.GONE
        canvasView.onSelectionChanged = {
            confirmButton.visibility = if (canvasView.selectionInBitmapSpace() != null) View.VISIBLE else View.GONE
        }
        confirmButton.setOnClickListener {
            val rect = canvasView.selectionInBitmapSpace() ?: return@setOnClickListener
            val cropped = Bitmap.createBitmap(bitmap, rect.left, rect.top, rect.width(), rect.height())
            val stream = ByteArrayOutputStream()
            cropped.compress(Bitmap.CompressFormat.PNG, 100, stream)
            cropped.recycle()
            onConfirm(stream.toByteArray())
        }
        cancelButton.setOnClickListener { onCancel() }
    }

    fun attach() {
        windowManager.addView(view, layoutParams)
    }

    fun detach() {
        windowManager.removeView(view)
        bitmap.recycle()
    }
}
