package com.yonderchat.not_interested

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper

class ScreenCaptureManager(
    private val context: Context,
    private val onFrame: (Bitmap) -> Unit,
    private val onProjectionStopped: () -> Unit,
) {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var stoppedExternally = false

    private val thread = HandlerThread("ScreenCaptureThread").also { it.start() }
    private val handler = Handler(thread.looper)
    private val mainHandler = Handler(Looper.getMainLooper())

    fun start(resultCode: Int, resultData: Intent, width: Int, height: Int, dpi: Int) {
        val mgr = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mgr.getMediaProjection(resultCode, resultData)

        // API 34+ REQUIREMENT: register callback BEFORE createVirtualDisplay().
        // Without this, createVirtualDisplay() throws IllegalStateException on API 34+.
        // onStop() fires when: screen locks, another app starts projection, user taps system chip.
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stoppedExternally = true
                onProjectionStopped()
            }
        }, mainHandler) // mainHandler so onStop() runs on main thread — safe to call stop() from there

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            try {
                val plane = image.planes[0]
                val rowStride = plane.rowStride
                val pixelStride = plane.pixelStride
                val rowPadding = rowStride - pixelStride * width
                val bitmap = Bitmap.createBitmap(
                    width + rowPadding / pixelStride,
                    height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(plane.buffer)
                onFrame(bitmap)
            } finally {
                image.close()
            }
        }, handler)

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "NotInterestedCapture",
            width, height, dpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            handler
        )
    }

    fun stop() {
        // Correct teardown order: VirtualDisplay → ImageReader → HandlerThread → MediaProjection
        virtualDisplay?.release()
        imageReader?.close()
        thread.quitSafely()
        if (!stoppedExternally) {
            // Only call stop() if we weren't already stopped by the system via onStop() callback
            mediaProjection?.stop()
        }
        virtualDisplay = null
        imageReader = null
        mediaProjection = null
        stoppedExternally = false
    }
}
