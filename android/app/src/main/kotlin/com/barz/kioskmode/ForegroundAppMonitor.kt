package com.barz.kioskmode

import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.SystemClock

class ForegroundAppMonitor(private val context: Context) {
    fun currentForegroundPackage(): String? {
        val usageStats = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 10_000
        return usageStats.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            .maxByOrNull { it.lastTimeUsed }
            ?.packageName
    }

    fun monotonicNowMs(): Long = SystemClock.elapsedRealtime()
}

