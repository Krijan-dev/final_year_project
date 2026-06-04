package com.example.life_pattern_tracker

import android.content.Context

/**
 * Builds daily screen-time summary from [UsageEventsScreenTimeCalculator] (queryEvents only).
 */
object UsageStatsCalculator {

    const val SCREEN_TIME_SOURCE_LABEL = UsageEventsScreenTimeCalculator.SOURCE_LABEL

    data class DayUsage(
        val totalScreenTimeMinutes: Int,
        val hourlyUsageMinutes: List<Int>,
        val apps: List<AppUsage>,
        val screenTimeSource: String = SCREEN_TIME_SOURCE_LABEL,
        val packagesFromEvents: List<UsageEventsScreenTimeCalculator.PackageScreenTime> = emptyList(),
    )

    data class AppUsage(
        val packageName: String,
        val usageTimeMinutes: Int,
        val totalTimeMs: Long,
        val lastUsed: Long,
        val buckets: List<UsageEventsScreenTimeCalculator.UsageSession>,
    )

    fun compute(
        context: Context,
        startMillis: Long,
        endMillis: Long,
        excludePackage: String?,
    ): DayUsage {
        val effectiveEnd = minOf(endMillis, System.currentTimeMillis())
        if (effectiveEnd <= startMillis) {
            return DayUsage(0, List(24) { 0 }, emptyList())
        }

        val packages = UsageEventsScreenTimeCalculator.computeFromEvents(
            context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager,
            startMillis,
            effectiveEnd,
            excludePackage,
        )

        val apps = packages.map { pkg ->
            AppUsage(
                packageName = pkg.packageName,
                usageTimeMinutes = msToMinutes(pkg.totalTimeMs),
                totalTimeMs = pkg.totalTimeMs,
                lastUsed = pkg.lastUsed,
                buckets = pkg.buckets,
            )
        }.filter { it.usageTimeMinutes > 0 }

        val totalMinutes = apps.sumOf { it.usageTimeMinutes }
        val hourly = UsageEventsScreenTimeCalculator.hourlyMinutesFromSessions(
            packages,
            startMillis,
            effectiveEnd,
        )

        return DayUsage(
            totalScreenTimeMinutes = totalMinutes,
            hourlyUsageMinutes = hourly,
            apps = apps,
            packagesFromEvents = packages,
        )
    }

    private fun msToMinutes(ms: Long): Int = (ms / 60_000L).toInt().coerceAtLeast(0)
}
