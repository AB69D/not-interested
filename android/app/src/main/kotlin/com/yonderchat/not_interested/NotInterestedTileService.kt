package com.yonderchat.not_interested

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class NotInterestedTileService : TileService() {

    override fun onStartListening() = updateTile()
    override fun onTileAdded() = updateTile()

    override fun onClick() {
        val running = NotInterestedService.isRunning.get()
        if (running) {
            NotInterestedService.stop(this)
        } else {
            val code = MediaProjectionStore.resultCode
            val data = MediaProjectionStore.resultData
            if (code != 0 && data != null) {
                NotInterestedService.start(this, code, data, 480, 854, 0.6f)
            } else {
                // No projection token — open the app so user can tap the shield
                val intent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    val pending = PendingIntent.getActivity(
                        this, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    startActivityAndCollapse(pending)
                } else {
                    @Suppress("DEPRECATION")
                    startActivityAndCollapse(intent)
                }
                return
            }
        }
        updateTile()
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val running = NotInterestedService.isRunning.get()
        tile.state = if (running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = "Content Filter"
        tile.contentDescription = if (running) "Active" else "Off"
        tile.updateTile()
    }
}
