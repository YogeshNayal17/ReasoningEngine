package com.reasonai.reason_ai.overlay

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import com.reasonai.reason_ai.R
import kotlin.math.abs

/**
 * Owns the single overlay window: a collapsed circular bubble that reacts
 * to three gestures, disambiguated by finger travel and hold duration
 * rather than a click listener:
 * - drag: moves the bubble ([DRAG_THRESHOLD_PX] of travel).
 * - short tap on the collapsed bubble: requests a capture, which
 *   [OverlayService] follows with a full-screen selection overlay — the
 *   product's core "tap bubble, drag to select" interaction.
 * - long press ([LONG_PRESS_MS] held without moving): expands the bubble
 *   into a panel with a close/stop action. A short tap while expanded
 *   collapses it back.
 */
class OverlayBubbleController(
    context: Context,
    private val windowManager: WindowManager,
    private val onCloseRequested: () -> Unit,
    private val onCaptureRequested: () -> Unit,
) {
    private val view: View = LayoutInflater.from(context).inflate(R.layout.overlay_bubble, null)
    private val collapsedIcon: View = view.findViewById(R.id.bubble_collapsed)
    private val expandedPanel: View = view.findViewById(R.id.bubble_expanded)

    private val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.TOP or Gravity.START
        x = 0
        y = 300
    }

    private var isExpanded = false
    private var downRawX = 0f
    private var downRawY = 0f
    private var downLayoutX = 0
    private var downLayoutY = 0
    private var hasMoved = false
    private var longPressFired = false

    private val longPressHandler = Handler(Looper.getMainLooper())
    private val longPressRunnable = Runnable {
        longPressFired = true
        if (!isExpanded) toggleExpanded()
    }

    init {
        expandedPanel.visibility = View.GONE
        view.findViewById<View>(R.id.bubble_close).setOnClickListener { onCloseRequested() }
        view.setOnTouchListener(::handleTouch)
    }

    fun attach() {
        windowManager.addView(view, layoutParams)
    }

    fun detach() {
        longPressHandler.removeCallbacks(longPressRunnable)
        windowManager.removeView(view)
    }

    /** Hidden briefly during capture so the bubble itself doesn't end up in the screenshot. */
    fun setVisible(visible: Boolean) {
        view.visibility = if (visible) View.VISIBLE else View.GONE
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun handleTouch(v: View, event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downRawX = event.rawX
                downRawY = event.rawY
                downLayoutX = layoutParams.x
                downLayoutY = layoutParams.y
                hasMoved = false
                longPressFired = false
                longPressHandler.postDelayed(longPressRunnable, LONG_PRESS_MS)
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - downRawX
                val dy = event.rawY - downRawY
                if (!hasMoved && (abs(dx) > DRAG_THRESHOLD_PX || abs(dy) > DRAG_THRESHOLD_PX)) {
                    hasMoved = true
                    longPressHandler.removeCallbacks(longPressRunnable)
                }
                if (hasMoved) {
                    layoutParams.x = downLayoutX + dx.toInt()
                    layoutParams.y = downLayoutY + dy.toInt()
                    windowManager.updateViewLayout(view, layoutParams)
                }
                return true
            }

            MotionEvent.ACTION_UP -> {
                longPressHandler.removeCallbacks(longPressRunnable)
                if (!hasMoved && !longPressFired) {
                    if (isExpanded) {
                        toggleExpanded()
                    } else {
                        onCaptureRequested()
                    }
                }
                return true
            }
        }
        return false
    }

    private fun toggleExpanded() {
        isExpanded = !isExpanded
        collapsedIcon.visibility = if (isExpanded) View.GONE else View.VISIBLE
        expandedPanel.visibility = if (isExpanded) View.VISIBLE else View.GONE
        windowManager.updateViewLayout(view, layoutParams)
    }

    companion object {
        private const val DRAG_THRESHOLD_PX = 12
        private const val LONG_PRESS_MS = 400L
    }
}
