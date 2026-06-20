package com.yonderchat.not_interested

import android.content.Context
import android.os.PowerManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

// Runs every 15 minutes (WorkManager minimum interval) to detect if the service died
// without triggering START_STICKY restart (e.g. force-stopped by OEM battery manager,
// or killed while the screen was off with no pending restart intent).
//
// If the service is dead AND the device is not in Doze, shows a re-acquisition notification.
// Does NOT attempt to restart the service — MediaProjection requires fresh user consent.
class ServiceWatchdogWorker(
    private val context: Context,
    workerParams: WorkerParameters,
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        if (!NotInterestedService.isRunning.get()) {
            val pm = context.getSystemService(PowerManager::class.java)
            val isInteractive = pm.isInteractive  // screen is on
            // Only nag the user when the screen is on; no notification to a sleeping device
            if (isInteractive) {
                // Delegate to the service to show the notification (reuse existing channel)
                val intent = android.content.Intent(context, NotInterestedService::class.java)
                // Service is not running, so this is a lightweight start just to show a notification.
                // The service will detect null action and show recovery notification then stop.
                context.startService(intent)
            }
        }
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "not_interested_watchdog"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<ServiceWatchdogWorker>(
                15, TimeUnit.MINUTES
            ).build()
            // KEEP: do not reset the countdown timer on subsequent schedule calls
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
