package com.yonderchat.not_interested

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class NotInterestedService : Service() {

    private lateinit var overlayManager: OverlayManager
    private lateinit var nudeNetDetector: NudeNetDetector
    private lateinit var captureManager: ScreenCaptureManager
    private val whitelistManager = AppWhitelistManager()

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pauseResumeRunnable = Runnable {
        isPaused.set(false)
        updateNotification(false)
    }
    private val inferenceExecutor = Executors.newSingleThreadExecutor()
    private val pendingFrame = AtomicReference<Bitmap?>(null)
    private val isInferring = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isPaused.set(true)
                    pendingFrame.getAndSet(null)?.recycle()
                    mainHandler.post { overlayManager.clearRegions() }
                }
                Intent.ACTION_SCREEN_ON -> isPaused.set(false)
                Intent.ACTION_USER_PRESENT -> {
                    // Device unlocked — if the projection was stopped by screen lock, notify user
                    if (!isRunning.get()) {
                        showReacquisitionNotification()
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning.set(true)

        // Call startForeground() IMMEDIATELY in onCreate() — this covers the START_STICKY
        // restart case where onStartCommand() receives a null intent and handleStart() is
        // never called, which would otherwise trigger ForegroundServiceDidNotStartInTimeException.
        startAsForeground()

        overlayManager = OverlayManager(this)
        nudeNetDetector = NudeNetDetector(this)
        captureManager = ScreenCaptureManager(this, ::onFrame, ::onProjectionStopped)

        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        })

        inferenceExecutor.execute {
            try {
                nudeNetDetector.load()
                mainHandler.post { notifyFlutter("onModelReady", emptyMap()) }
            } catch (e: Exception) {
                mainHandler.post {
                    notifyFlutter("onModelError", mapOf("error" to (e.message ?: "Model load failed")))
                }
                stopSelf()
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // null intent = START_STICKY restart after process kill.
        // The MediaProjection token is gone — cannot resume capture silently.
        // Show a notification so the user can tap to re-enable, then stop.
        if (intent == null) {
            showReacquisitionNotification()
            stopSelf()
            return START_NOT_STICKY
        }

        when (intent.action) {
            ACTION_START -> handleStart(intent)
            ACTION_PAUSE -> {
                isPaused.set(true)
                pendingFrame.getAndSet(null)?.recycle()
                mainHandler.removeCallbacks(pauseResumeRunnable)
                mainHandler.postDelayed(pauseResumeRunnable, 15 * 60 * 1000L)
                updateNotification(true)
            }
            ACTION_STOP -> stopSelf()
            ACTION_SET_THRESHOLD -> {
                confidenceThreshold = intent.getFloatExtra(EXTRA_THRESHOLD, 0.6f)
            }
            ACTION_SET_WHITELIST -> {
                val pkgs = intent.getStringArrayExtra("packages")?.toSet() ?: emptySet()
                whitelistManager.setWhitelist(pkgs)
            }
        }
        return START_STICKY
    }

    private var confidenceThreshold = 0.6f
    private var frameCount = 0
    private val frameSkip = 4

    private fun handleStart(intent: Intent) {
        confidenceThreshold = intent.getFloatExtra(EXTRA_THRESHOLD, 0.6f)
        // startForeground() was already called in onCreate() — update notification to running state
        updateNotification(false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) overlayManager.show()

        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, -1)
        @Suppress("DEPRECATION")
        val resultData = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA) ?: return

        val width = intent.getIntExtra(EXTRA_WIDTH, 480)
        val height = intent.getIntExtra(EXTRA_HEIGHT, 854)
        captureManager.start(resultCode, resultData, width, height, resources.displayMetrics.densityDpi)
    }

    // Called on the main thread when the system stops the MediaProjection session.
    // Triggers: screen lock (Android 15 QPR1+), another app starts projection, user taps chip.
    private fun onProjectionStopped() {
        isPaused.set(true)
        pendingFrame.getAndSet(null)?.recycle()
        overlayManager.clearRegions()
        overlayManager.hide()
        showReacquisitionNotification()
        stopSelf()
    }

    private fun onFrame(bitmap: Bitmap) {
        if (isPaused.get() || whitelistManager.isCurrentAppWhitelisted(this)) { bitmap.recycle(); return }

        frameCount++
        if (frameCount % frameSkip != 0) { bitmap.recycle(); return }

        val old = pendingFrame.getAndSet(bitmap)
        old?.recycle()

        if (isInferring.compareAndSet(false, true)) scheduleInference()
    }

    private fun scheduleInference() {
        inferenceExecutor.execute {
            val frame = pendingFrame.getAndSet(null) ?: run {
                isInferring.set(false)
                return@execute
            }
            try {
                val hasSkin = SkinDetector.getSkinRegions(frame).isNotEmpty()
                val detections = if (hasSkin) nudeNetDetector.detect(frame, confidenceThreshold)
                                else emptyList()
                mainHandler.post {
                    if (detections.isNotEmpty()) {
                        overlayManager.updateRegions(detections)
                        notifyFlutter("onDetectionEvent", mapOf("count" to detections.size))
                    } else {
                        overlayManager.clearRegions()
                    }
                }
            } catch (_: Exception) {
            } finally {
                frame.recycle()
                isInferring.set(false)
                if (pendingFrame.get() != null && isInferring.compareAndSet(false, true)) {
                    scheduleInference()
                }
            }
        }
    }

    private fun notifyFlutter(method: String, args: Map<String, Any>) {
        val engine = MainActivity.flutterEngine ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_SCREEN_CAPTURE)
            .invokeMethod(method, args)
    }

    override fun onDestroy() {
        isRunning.set(false)
        unregisterReceiver(screenReceiver)
        captureManager.stop()
        overlayManager.hide()
        nudeNetDetector.close()
        inferenceExecutor.shutdownNow()
        pendingFrame.getAndSet(null)?.recycle()
        mainHandler.removeCallbacks(pauseResumeRunnable)
        super.onDestroy()
    }

    private fun updateNotification(paused: Boolean) = startAsForeground(paused)

    private fun startAsForeground(paused: Boolean = false) {
        val channelId = "not_interested_channel"
        val channel = NotificationChannel(channelId, "Content Filter", NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)

        val openIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopIntent = PendingIntent.getService(
            this, 0,
            Intent(this, NotInterestedService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Content Filter Active")
            .setContentText(if (paused) "Paused — resumes automatically in 15 min" else "Tap to open · Monitoring screen")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(openIntent)
            .addAction(android.R.drawable.ic_delete, "Stop", stopIntent)
            .setOngoing(true)

        if (!paused) {
            val pauseIntent = PendingIntent.getService(
                this, 1,
                Intent(this, NotInterestedService::class.java).apply { action = ACTION_PAUSE },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, "Pause 15 min", pauseIntent)
        }

        val notification = builder.build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    // Shows a tap-to-restart notification after the projection session ends unexpectedly.
    // Triggered by: screen lock (Android 15), START_STICKY restart with no token,
    // another app taking over the MediaProjection session.
    private fun showReacquisitionNotification() {
        val channelId = "not_interested_recovery"
        val channel = NotificationChannel(channelId, "Content Filter Status", NotificationManager.IMPORTANCE_DEFAULT)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)

        val openIntent = PendingIntent.getActivity(
            this, 2,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Content Filter Paused")
            .setContentText("Tap to re-enable protection")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(openIntent)
            .setAutoCancel(true)
            .build()

        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_RECOVERY_ID, notification)
    }

    companion object {
        const val ACTION_START = "com.yonderchat.not_interested.START"
        const val ACTION_STOP = "com.yonderchat.not_interested.STOP"
        const val ACTION_PAUSE = "com.yonderchat.not_interested.PAUSE"
        const val ACTION_SET_THRESHOLD = "com.yonderchat.not_interested.SET_THRESHOLD"
        const val ACTION_SET_WHITELIST = "com.yonderchat.not_interested.SET_WHITELIST"
        const val EXTRA_RESULT_CODE = "RESULT_CODE"
        const val EXTRA_RESULT_DATA = "RESULT_DATA"
        const val EXTRA_WIDTH = "WIDTH"
        const val EXTRA_HEIGHT = "HEIGHT"
        const val EXTRA_THRESHOLD = "THRESHOLD"
        const val NOTIFICATION_ID = 1001
        const val NOTIFICATION_RECOVERY_ID = 1002
        const val CHANNEL_SCREEN_CAPTURE = "com.yonderchat.not_interested/screen_capture"

        val isRunning = AtomicBoolean(false)

        fun start(context: Context, resultCode: Int, resultData: Intent, width: Int, height: Int, threshold: Float) {
            context.startForegroundService(
                Intent(context, NotInterestedService::class.java).apply {
                    action = ACTION_START
                    putExtra(EXTRA_RESULT_CODE, resultCode)
                    putExtra(EXTRA_RESULT_DATA, resultData)
                    putExtra(EXTRA_WIDTH, width)
                    putExtra(EXTRA_HEIGHT, height)
                    putExtra(EXTRA_THRESHOLD, threshold)
                }
            )
        }

        fun stop(context: Context) {
            context.startService(Intent(context, NotInterestedService::class.java).apply {
                action = ACTION_STOP
            })
        }

        fun setThreshold(context: Context, threshold: Float) {
            context.startService(Intent(context, NotInterestedService::class.java).apply {
                action = ACTION_SET_THRESHOLD
                putExtra(EXTRA_THRESHOLD, threshold)
            })
        }
    }
}
