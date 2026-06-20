package com.yonderchat.not_interested

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // MediaProjection requires user consent — cannot auto-start capture on boot.
            // Boot receiver is a placeholder for future: restore settings, show notification, etc.
        }
    }
}
