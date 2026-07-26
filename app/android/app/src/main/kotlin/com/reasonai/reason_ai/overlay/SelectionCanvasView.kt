package com.reasonai.reason_ai.overlay

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PointF
import android.graphics.Rect
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View
import kotlin.math.max
import kotlin.math.min

/**
 * Draws the captured screenshot full-bleed and lets the user drag a
 * selection rectangle over it, dimming everything outside — the same
 * "snip tool" visual as the Flutter crop screen it replaces, but native
 * since it now has to render as a system overlay before the app opens.
 */
class SelectionCanvasView(context: Context, private val bitmap: Bitmap) : View(context) {

    /** Called on every touch update with the selection in view coordinates (or null). */
    var onSelectionChanged: ((RectF?) -> Unit)? = null

    private var selection: RectF? = null
    private var dragStart: PointF? = null

    private val dimPaint = Paint().apply { color = Color.argb(0x99, 0, 0, 0) }
    private val borderPaint = Paint().apply {
        color = Color.WHITE
        style = Paint.Style.STROKE
        strokeWidth = 4f
    }
    private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG)

    private val destRect = RectF()

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        // BoxFit.contain-equivalent: fit the bitmap inside the view, letterboxing
        // on whichever axis doesn't match the view's aspect ratio.
        val viewRatio = w.toFloat() / h.toFloat()
        val bitmapRatio = bitmap.width.toFloat() / bitmap.height.toFloat()
        if (bitmapRatio > viewRatio) {
            val scaledHeight = w / bitmapRatio
            val top = (h - scaledHeight) / 2
            destRect.set(0f, top, w.toFloat(), top + scaledHeight)
        } else {
            val scaledWidth = h * bitmapRatio
            val left = (w - scaledWidth) / 2
            destRect.set(left, 0f, left + scaledWidth, h.toFloat())
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawBitmap(bitmap, null, destRect, bitmapPaint)

        val sel = selection
        if (sel == null) {
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dimPaint)
            return
        }
        canvas.drawRect(0f, 0f, width.toFloat(), sel.top, dimPaint)
        canvas.drawRect(0f, sel.bottom, width.toFloat(), height.toFloat(), dimPaint)
        canvas.drawRect(0f, sel.top, sel.left, sel.bottom, dimPaint)
        canvas.drawRect(sel.right, sel.top, width.toFloat(), sel.bottom, dimPaint)
        canvas.drawRect(sel, borderPaint)
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                dragStart = PointF(event.x, event.y)
                selection = RectF(event.x, event.y, event.x, event.y)
            }

            MotionEvent.ACTION_MOVE -> {
                val start = dragStart ?: return true
                selection = RectF(
                    min(start.x, event.x),
                    min(start.y, event.y),
                    max(start.x, event.x),
                    max(start.y, event.y),
                )
            }

            MotionEvent.ACTION_UP -> Unit

            else -> return false
        }
        invalidate()
        onSelectionChanged?.invoke(selection)
        return true
    }

    /** Maps the current on-screen [selection] to bitmap-pixel coordinates, or null if too small. */
    fun selectionInBitmapSpace(): Rect? {
        val sel = selection ?: return null
        if (sel.width() < MIN_SELECTION_PX || sel.height() < MIN_SELECTION_PX) return null

        val scale = bitmap.width / destRect.width()
        val left = (sel.left - destRect.left).coerceIn(0f, destRect.width()) * scale
        val top = (sel.top - destRect.top).coerceIn(0f, destRect.height()) * scale
        val right = (sel.right - destRect.left).coerceIn(0f, destRect.width()) * scale
        val bottom = (sel.bottom - destRect.top).coerceIn(0f, destRect.height()) * scale
        return Rect(left.toInt(), top.toInt(), right.toInt(), bottom.toInt())
    }

    companion object {
        private const val MIN_SELECTION_PX = 8f
    }
}
