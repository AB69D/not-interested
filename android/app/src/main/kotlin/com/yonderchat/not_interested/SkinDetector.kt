package com.yonderchat.not_interested

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.RectF

object SkinDetector {
    private const val SKIN_THRESHOLD = 0.15f
    private const val SCAN_SIZE = 128

    fun getSkinRegions(bitmap: Bitmap): List<RectF> {
        val small = Bitmap.createScaledBitmap(bitmap, SCAN_SIZE, SCAN_SIZE, false)
        var skinCount = 0
        val total = SCAN_SIZE * SCAN_SIZE

        for (y in 0 until SCAN_SIZE) {
            for (x in 0 until SCAN_SIZE) {
                val pixel = small.getPixel(x, y)
                val r = Color.red(pixel) / 255f
                val g = Color.green(pixel) / 255f
                val b = Color.blue(pixel) / 255f
                if (isSkinPixel(r, g, b)) skinCount++
            }
        }

        small.recycle()

        return if (skinCount.toFloat() / total > SKIN_THRESHOLD) {
            listOf(RectF(0f, 0f, 1f, 1f)) // full frame; ML refines in Phase 4
        } else {
            emptyList()
        }
    }

    private fun isSkinPixel(r: Float, g: Float, b: Float): Boolean {
        val maxC = maxOf(r, g, b)
        val minC = minOf(r, g, b)
        val delta = maxC - minC

        if (maxC == 0f || delta == 0f) return false

        var h = when {
            maxC == r -> 60f * ((g - b) / delta % 6f)
            maxC == g -> 60f * ((b - r) / delta + 2f)
            else -> 60f * ((r - g) / delta + 4f)
        }
        if (h < 0) h += 360f

        val s = delta / maxC
        val v = maxC

        return h in 0f..50f && s in 0.23f..0.68f && v >= 0.35f
    }
}
