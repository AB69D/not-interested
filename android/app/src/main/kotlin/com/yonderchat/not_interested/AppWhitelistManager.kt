package com.yonderchat.not_interested

import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

class AppWhitelistManager {
    private val whitelist = CopyOnWriteArraySet<String>()

    fun setWhitelist(packages: Set<String>) {
        whitelist.clear()
        whitelist.addAll(packages)
    }

    fun isCurrentAppWhitelisted(context: Context): Boolean {
        if (whitelist.isEmpty()) return false
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return false
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60_000L, now)
            val top = stats?.maxByOrNull { it.lastTimeUsed }?.packageName ?: return false
            top in whitelist
        } catch (_: SecurityException) {
            false  // PACKAGE_USAGE_STATS not granted — fail open (don't whitelist)
        }
    }
}
