package com.yonderchat.not_interested

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                // MediaProjection requires fresh user consent — cannot auto-resume capture.
                // Only schedule watchdogs if the user had the filter enabled before this event,
                // so we can notify them to re-enable it after a reboot or app update.
                val prefs = context.getSharedPreferences("not_interested_prefs", Context.MODE_PRIVATE)
                if (prefs.getBoolean("was_running", false)) {
                    ServiceWatchdogWorker.schedule(context)
                    AlarmHeartbeatReceiver.schedule(context)
                }
            }
        }
    }
}
