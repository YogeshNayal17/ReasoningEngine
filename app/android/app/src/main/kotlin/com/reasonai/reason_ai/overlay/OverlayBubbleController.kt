package com.reasonai.reason_ai.overlay

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import com.reasonai.reason_ai.R
import kotlin.math.abs

/**
 * Owns the single overlay window: a collapsed circular bubble that can be
 * dragged anywhere on screen, and expands into a small panel with a close
 * action on tap. A drag and a tap are disambiguated by total finger travel
 * ([DRAG_THRESHOLD_PX]) rather than a timer, so a slow tap never gets
 * misread as a drag.
 *
 * The expanded panel is intentionally just a label + close button today.
 * Milestone 3 (screen capture) adds its trigger as another child of
 * [expandedPanel] plus a new branch in [OverlayMethodChannelHandler] —
 * this class doesn't need to change shape to support that.
 */
class OverlayBubbleController(
    context: Context,
    private val windowManager: WindowManager,
    private val onCloseRequested: () -> Unit,
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

    init {
        expandedPanel.visibility = View.GONE
        view.findViewById<View>(R.id.bubble_close).setOnClickListener { onCloseRequested() }
        view.setOnTouchListener(::handleTouch)
    }

    fun attach() {
        windowManager.addView(view, layoutParams)
    }

    fun detach() {
        windowManager.removeView(view)
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
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - downRawX
                val dy = event.rawY - downRawY
                if (!hasMoved && (abs(dx) > DRAG_THRESHOLD_PX || abs(dy) > DRAG_THRESHOLD_PX)) {
                    hasMoved = true
                }
                if (hasMoved) {
                    layoutParams.x = downLayoutX + dx.toInt()
                    layoutParams.y = downLayoutY + dy.toInt()
                    windowManager.updateViewLayout(view, layoutParams)
                }
                return true
            }

            MotionEvent.ACTION_UP -> {
                if (!hasMoved) {
                    toggleExpanded()
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
    }
}
