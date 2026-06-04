package com.example.life_pattern_tracker

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

/**
 * Today's screen time from [UsageStatsManager.queryEvents] only (local midnight → now).
 */
object UsageEventsScreenTimeCalculator {

    const val SOURCE_LABEL = "Today · Usage events (midnight to now)"

    data class UsageSession(
        val startTime: Long,
        val endTime: Long,
        val duration: Long,
    )

    data class PackageScreenTime(
        val packageName: String,
        val totalTimeMs: Long,
        val buckets: List<UsageSession>,
        val lastUsed: Long,
    )

    fun localMidnightMillis(): Long {
        val c = Calendar.getInstance()
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }

    fun computeToday(
        context: Context,
        excludePackage: String?,
    ): List<PackageScreenTime> {
        val startMillis = localMidnightMillis()
        val endMillis = System.currentTimeMillis()
        if (endMillis <= startMillis) return emptyList()

        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        return computeFromEvents(manager, startMillis, endMillis, excludePackage)
    }

    fun computeFromEvents(
        manager: UsageStatsManager,
        startMillis: Long,
        endMillis: Long,
        excludePackage: String?,
    ): List<PackageScreenTime> {
        if (endMillis <= startMillis) return emptyList()

        val events = try {
            manager.queryEvents(startMillis, endMillis)
        } catch (_: Exception) {
            return emptyList()
        } ?: return emptyList()

        val sessionsByPkg = LinkedHashMap<String, MutableList<UsageSession>>()
        var currentPkg: String? = null
        var currentStart = 0L

        fun clipEnd(rawEnd: Long): Long = minOf(maxOf(rawEnd, startMillis), endMillis)

        fun clipStart(rawStart: Long): Long = maxOf(rawStart, startMillis)

        fun addSession(pkg: String, sessionStart: Long, sessionEnd: Long) {
            if (pkg.isBlank()) return
            if (ScreenTimeAppFilter.isExcluded(pkg, excludePackage)) return
            val start = clipStart(sessionStart)
            val end = clipEnd(sessionEnd)
            if (end <= start) return
            val duration = end - start
            if (duration <= 0L) return
            val list = sessionsByPkg.getOrPut(pkg) { mutableListOf() }
            list.add(UsageSession(startTime = start, endTime = end, duration = duration))
        }

        fun closeCurrent(until: Long) {
            val pkg = currentPkg ?: return
            if (currentStart <= 0L) {
                currentPkg = null
                currentStart = 0L
                return
            }
            addSession(pkg, currentStart, until)
            currentPkg = null
            currentStart = 0L
        }

        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName?.trim().orEmpty()
            if (pkg.isEmpty()) continue

            val ts = event.timeStamp
            if (ts < startMillis || ts > endMillis) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    closeCurrent(ts)
                    currentPkg = pkg
                    currentStart = clipStart(ts)
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (pkg == currentPkg) {
                        closeCurrent(ts)
                    }
                }
            }
        }

        // App still in foreground: count until now.
        closeCurrent(endMillis)

        val result = mutableListOf<PackageScreenTime>()
        for ((pkg, sessions) in sessionsByPkg) {
            if (sessions.isEmpty()) continue
            val totalMs = sessions.sumOf { it.duration }
            if (totalMs <= 0L) continue
            val lastUsed = sessions.maxOf { it.endTime }
            result.add(
                PackageScreenTime(
                    packageName = pkg,
                    totalTimeMs = totalMs,
                    buckets = sessions.sortedBy { it.startTime },
                    lastUsed = lastUsed,
                )
            )
        }
        return result.sortedByDescending { it.totalTimeMs }
    }

    fun toMethodChannelMaps(packages: List<PackageScreenTime>): List<HashMap<String, Any>> {
        return packages.map { pkg ->
            hashMapOf<String, Any>(
                "packageName" to pkg.packageName,
                "totalTime" to pkg.totalTimeMs,
                "buckets" to pkg.buckets.map { session ->
                    hashMapOf<String, Any>(
                        "startTime" to session.startTime,
                        "endTime" to session.endTime,
                        "duration" to session.duration,
                    )
                },
                "lastUsed" to pkg.lastUsed,
            )
        }
    }

    fun hourlyMinutesFromSessions(
        sessionsByPkg: List<PackageScreenTime>,
        dayStartMillis: Long,
        endMillis: Long,
    ): List<Int> {
        val hourlyMs = LongArray(24)
        for (pkg in sessionsByPkg) {
            for (session in pkg.buckets) {
                distributeSessionIntoHours(session, dayStartMillis, endMillis, hourlyMs)
            }
        }
        return List(24) { h -> (hourlyMs[h] / 60_000L).toInt() }
    }

    private fun distributeSessionIntoHours(
        session: UsageSession,
        dayStartMillis: Long,
        endMillis: Long,
        hourlyMs: LongArray,
    ) {
        var cursor = session.startTime
        val sessionEnd = minOf(session.endTime, endMillis)
        while (cursor < sessionEnd) {
            val hourIndex = ((cursor - dayStartMillis) / 3_600_000L).toInt()
            if (hourIndex < 0 || hourIndex >= 24) break
            val hourStart = dayStartMillis + hourIndex * 3_600_000L
            val hourEnd = minOf(hourStart + 3_600_000L, endMillis)
            val sliceEnd = minOf(sessionEnd, hourEnd)
            if (sliceEnd > cursor) {
                hourlyMs[hourIndex] += sliceEnd - cursor
            }
            cursor = hourEnd
        }
    }
}
