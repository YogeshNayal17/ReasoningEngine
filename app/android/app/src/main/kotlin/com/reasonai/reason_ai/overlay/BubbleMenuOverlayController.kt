package com.reasonai.reason_ai.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Point
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import com.reasonai.reason_ai.R

/**
 * Small popup shown right when the bubble is tapped, offering the two
 * capture entry points ("select on screen" vs "from clipboard/text").
 * Positioned near wherever the bubble currently sits rather than centered,
 * since the bubble is draggable and can end up anywhere on screen.
 *
 * Deliberately has no outside-tap-to-dismiss: a full-screen touch-catcher
 * behind a small WRAP_CONTENT popup is exactly the kind of complexity this
 * doesn't need when the close button already covers dismissal.
 */
class BubbleMenuOverlayController(
    context: Context,
    private val windowManager: WindowManager,
    bubblePosition: Point,
    onSelectScreen: () -> Unit,
    onClipboardText: () -> Unit,
    onDismiss: () -> Unit,
) {
    private val view: View = LayoutInflater.from(context).inflate(R.layout.bubble_menu, null)

    private val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.TOP or Gravity.START
    }

    init {
        val density = context.resources.displayMetrics.density
        val screenWidth = context.resources.displayMetrics.widthPixels
        val menuWidthPx = (MENU_WIDTH_DP * density).toInt()
        val menuHeightPx = (MENU_HEIGHT_DP * density).toInt()
        val bubbleSizePx = (BUBBLE_SIZE_DP * density).toInt()
        val marginPx = (MARGIN_DP * density).toInt()

        val maxX = (screenWidth - menuWidthPx - marginPx).coerceAtLeast(marginPx)
        layoutParams.x = (bubblePosition.x - menuWidthPx / 2).coerceIn(marginPx, maxX)

        val aboveY = bubblePosition.y - menuHeightPx - marginPx
        layoutParams.y = if (aboveY >= marginPx) aboveY else bubblePosition.y + bubbleSizePx + marginPx

        view.findViewById<View>(R.id.bubble_menu_select_screen).setOnClickListener { onSelectScreen() }
        view.findViewById<View>(R.id.bubble_menu_clipboard).setOnClickListener { onClipboardText() }
        view.findViewById<View>(R.id.bubble_menu_close).setOnClickListener { onDismiss() }
    }

    fun attach() {
        windowManager.addView(view, layoutParams)
    }

    fun detach() {
        windowManager.removeView(view)
    }

    companion object {
        private const val MENU_WIDTH_DP = 260
        private const val MENU_HEIGHT_DP = 190
        private const val BUBBLE_SIZE_DP = 56
        private const val MARGIN_DP = 16
    }
}
