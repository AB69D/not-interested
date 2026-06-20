package com.yonderchat.not_interested

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.View

class BlurOverlayView(context: Context) : View(context) {

    private val paint = Paint().apply {
        color = Color.argb(200, 10, 10, 10)
        isAntiAlias = false
    }

    private var regions: List<RectF> = emptyList()

    fun updateRegions(newRegions: List<RectF>) {
        regions = newRegions
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        for (r in regions) {
            canvas.drawRect(r.left * w, r.top * h, r.right * w, r.bottom * h, paint)
        }
    }
}
