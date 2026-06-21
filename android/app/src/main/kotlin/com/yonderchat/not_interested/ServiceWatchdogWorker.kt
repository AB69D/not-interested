package com.yonderchat.not_interested

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

// Runs every 15 minutes (WorkManager minimum) to detect if the service died without triggering
// a START_STICKY restart — e.g. OEM battery manager force-stop, or killed while screen was off.
// Shows a recovery notification directly (does NOT start the service — MediaProjection requires
// fresh user consent and cannot be re-acquired without an Activity).
class ServiceWatchdogWorker(
    private val context: Context,
    workerParams: WorkerParameters,
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        if (!NotInterestedService.isRunning.get()) {
            val pm = context.getSystemService(PowerManager::class.java)
            if (pm.isInteractive) {
                showRecoveryNotification()
            }
        }
        return Result.success()
    }

    private fun showRecoveryNotification() {
        val nm = context.getSystemService(NotificationManager::class.java)
        val channelId = "not_interested_recovery"
        nm.createNotificationChannel(
            NotificationChannel(channelId, "Content Filter Status", NotificationManager.IMPORTANCE_DEFAULT)
        )
        val openIntent = PendingIntent.getActivity(
            context, 200,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        nm.notify(
            1004,
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
        private const val WORK_NAME = "not_interested_watchdog"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<ServiceWatchdogWorker>(
                15, TimeUnit.MINUTES
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
