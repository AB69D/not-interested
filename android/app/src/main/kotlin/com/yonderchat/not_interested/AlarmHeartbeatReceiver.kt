package com.yonderchat.not_interested

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

// Self-chaining AlarmManager heartbeat. Fires every ~15 minutes (the OS may batch or delay),
// even during Doze. If the service has died unexpectedly, posts a recovery notification.
// Complements the WorkManager watchdog: WorkManager can be deferred by the OS for hours on
// some OEMs (Samsung/Xiaomi), whereas this alarm fires via the wakeup alarm path.
class AlarmHeartbeatReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_HEARTBEAT -> {
                if (!NotInterestedService.isRunning.get()) {
                    showRecoveryNotification(context)
                }
                // Always reschedule — keeps the chain alive even if onDestroy was never called
                schedule(context)
            }
            // User re-granted SCHEDULE_EXACT_ALARM permission — upgrade to exact alarms
            ACTION_ALARM_PERMISSION_CHANGED -> schedule(context)
        }
    }

    private fun showRecoveryNotification(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        val channelId = "not_interested_recovery"
        nm.createNotificationChannel(
            NotificationChannel(channelId, "Content Filter Status", NotificationManager.IMPORTANCE_DEFAULT)
        )
        val openIntent = PendingIntent.getActivity(
            context, 300,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        nm.notify(
            NOTIFICATION_ID,
            NotificationCompat.Builder(context, channelId)
                .setContentTitle("Content Filter Paused")
                .setContentText("Tap to re-enable protection")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentIntent(openIntent)
                .setAutoCancel(true)
                .build(),
        )
    }

    companion object {
        const val ACTION_HEARTBEAT = "com.yonderchat.not_interested.HEARTBEAT"
        const val ACTION_ALARM_PERMISSION_CHANGED =
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
        private const val NOTIFICATION_ID = 1003
        private const val REQUEST_CODE = 42

        fun schedule(context: Context, delayMs: Long = 15 * 60 * 1000L) {
            val am = context.getSystemService(AlarmManager::class.java)
            val pi = buildPendingIntent(context) ?: return
            val triggerAt = System.currentTimeMillis() + delayMs
            // Use exact alarm when the permission is available; fall back to inexact otherwise.
            // setAndAllowWhileIdle fires even in Doze; it's just not guaranteed to the millisecond.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && am.canScheduleExactAlarms()) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }

        fun cancel(context: Context) {
            val am = context.getSystemService(AlarmManager::class.java)
            val pi = buildPendingIntent(context, PendingIntent.FLAG_NO_CREATE) ?: return
            am.cancel(pi)
        }

        private fun buildPendingIntent(context: Context, extraFlags: Int = 0): PendingIntent? =
            PendingIntent.getBroadcast(
                context, REQUEST_CODE,
                Intent(context, AlarmHeartbeatReceiver::class.java).apply { action = ACTION_HEARTBEAT },
                extraFlags or PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
