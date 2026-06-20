package com.yonderchat.not_interested

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val screenCaptureChannelName = "com.yonderchat.not_interested/screen_capture"
    private val overlayChannelName = "com.yonderchat.not_interested/overlay"

    private var pendingCaptureResult: MethodChannel.Result? = null
    private var pendingOverlayResult: MethodChannel.Result? = null

    private lateinit var mediaProjectionManager: MediaProjectionManager

    companion object {
        var flutterEngine: FlutterEngine? = null
        const val REQUEST_MEDIA_PROJECTION = 1001
        const val REQUEST_OVERLAY_PERMISSION = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MainActivity.flutterEngine = flutterEngine
        mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        setupScreenCaptureChannel(flutterEngine)
        setupOverlayChannel(flutterEngine)
        // Start the 15-minute watchdog on every app open
        ServiceWatchdogWorker.schedule(this)
        // Request battery optimization exemption if not already granted
        requestBatteryOptimizationExemption()
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(PowerManager::class.java)
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                )
            }
        }
    }

    private fun setupScreenCaptureChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, screenCaptureChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            pendingOverlayResult = result
                            startActivityForResult(
                                Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")),
                                REQUEST_OVERLAY_PERMISSION
                            )
                        } else {
                            requestMediaProjection(result)
                        }
                    }
                    "startCapture" -> {
                        val width = call.argument<Int>("width") ?: 480
                        val height = call.argument<Int>("height") ?: 854
                        val threshold = (call.argument<Double>("threshold") ?: 0.6).toFloat()
                        val code = MediaProjectionStore.resultCode
                        val data = MediaProjectionStore.resultData
                        if (code == 0 || data == null) {
                            result.error("NO_PERMISSION", "MediaProjection not granted", null)
                            return@setMethodCallHandler
                        }
                        NotInterestedService.start(this, code, data, width, height, threshold)
                        result.success(null)
                    }
                    "stopCapture" -> {
                        NotInterestedService.stop(this)
                        result.success(null)
                    }
                    "isServiceRunning" -> result.success(NotInterestedService.isRunning.get())
                    "hasProjectionToken" -> result.success(
                        MediaProjectionStore.resultCode != 0 && MediaProjectionStore.resultData != null
                    )
                    "getInstalledApps" -> {
                        val pm = packageManager
                        val apps = pm.getInstalledApplications(0)
                            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
                            .map { mapOf("name" to pm.getApplicationLabel(it).toString(), "packageName" to it.packageName) }
                            .sortedBy { it["name"] as String }
                        result.success(apps)
                    }
                    "setWhitelistedApps" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = (call.arguments as? List<*>)?.filterIsInstance<String>() ?: emptyList()
                        val intent = Intent(this, NotInterestedService::class.java).apply {
                            action = NotInterestedService.ACTION_SET_WHITELIST
                            putExtra("packages", packages.toTypedArray())
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupOverlayChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, overlayChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOverlay", "hideOverlay", "clearBlurRegions", "updateBlurRegions" -> result.success(null)
                    "setThreshold" -> {
                        val threshold = (call.argument<Double>("threshold") ?: 0.6).toFloat()
                        NotInterestedService.setThreshold(this, threshold)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestMediaProjection(result: MethodChannel.Result) {
        pendingCaptureResult = result
        // API 34+: force full-display capture so the user cannot accidentally select single-app
        // mode, which would make the content filter miss everything outside that one app.
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val config = MediaProjectionConfig.createConfigForDefaultDisplay()
            mediaProjectionManager.createScreenCaptureIntent(config)
        } else {
            mediaProjectionManager.createScreenCaptureIntent()
        }
        startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_OVERLAY_PERMISSION -> {
                if (Settings.canDrawOverlays(this)) {
                    requestMediaProjection(pendingOverlayResult ?: return)
                } else {
                    pendingOverlayResult?.success(false)
                }
                pendingOverlayResult = null
            }
            REQUEST_MEDIA_PROJECTION -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    MediaProjectionStore.resultCode = resultCode
                    MediaProjectionStore.resultData = data
                    pendingCaptureResult?.success(true)
                } else {
                    pendingCaptureResult?.success(false)
                }
                pendingCaptureResult = null
            }
        }
    }

    override fun onDestroy() {
        if (isFinishing) MainActivity.flutterEngine = null
        super.onDestroy()
    }
}

object MediaProjectionStore {
    var resultCode: Int = 0
    var resultData: Intent? = null
}
