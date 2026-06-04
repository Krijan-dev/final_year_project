package com.example.life_pattern_tracker

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

/** Reads Health Connect directly (works when the Flutter health plugin SDK check is too strict). */
object HealthConnectBridge {

    private const val STALE_AFTER_HOURS = 6L
    private const val STALE_CHECK_FROM_HOUR = 10

    private data class FreshnessSnapshot(
        val lastModified: Instant?,
        val lastOriginPackage: String?,
    )

    private sealed class OriginFilter {
        data object All : OriginFilter()
        data class FitnessOnly(val installedPackages: Set<String>) : OriginFilter()
        data class Primary(val packageName: String) : OriginFilter()
    }

    fun sdkStatus(context: Context): Int =
        HealthConnectClient.getSdkStatus(context)

    fun isSdkUsable(status: Int): Boolean =
        status == HealthConnectClient.SDK_AVAILABLE ||
            status == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED

    /** Steps + Sleep — must be requested together so HC does not only show Steps. */
    fun requiredReadPermissions(): Set<String> = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
    )

    suspend fun readSummary(context: Context): Map<String, Any?> = withContext(Dispatchers.IO) {
        val status = sdkStatus(context)
        val installed = FitnessAppRegistry.getInstalled(context)
        val installedMaps = installed.map {
            mapOf(
                "packageName" to it.packageName,
                "displayName" to it.displayName,
            )
        }
        val out = hashMapOf<String, Any?>(
            "sdkStatus" to status,
            "permissionsGranted" to false,
            "stepsToday" to 0,
            "sleepHours" to null,
            "error" to null,
            "installedFitnessApps" to installedMaps,
            "dataSourceLabels" to emptyList<String>(),
            "lastDataUpdateMillis" to null,
            "lastDataSourceLabel" to null,
            "dataMayBeStale" to false,
        )

        if (!isSdkUsable(status)) {
            out["error"] = "health_connect_not_installed"
            return@withContext out
        }

        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        val stepsPerm = HealthPermission.getReadPermission(StepsRecord::class)
        val sleepPerm = HealthPermission.getReadPermission(SleepSessionRecord::class)
        val hasSteps = granted.contains(stepsPerm)
        val hasSleep = granted.contains(sleepPerm)
        out["stepsPermissionGranted"] = hasSteps
        out["sleepPermissionGranted"] = hasSleep
        out["permissionsGranted"] = hasSteps || hasSleep

        if (!hasSteps && !hasSleep) {
            out["error"] = "permissions_missing"
            return@withContext out
        }

        val zone = ZoneId.systemDefault()
        val now = ZonedDateTime.now(zone)
        val startOfDay = now.toLocalDate().atStartOfDay(zone)
        val startInstant = startOfDay.toInstant()
        val endInstant = now.toInstant()
        // Last night: from yesterday 00:00 through now (captures 10pm–7am sessions).
        val sleepStart = startOfDay.minusDays(1).toInstant()

        val sourcesUsed = linkedSetOf<String>()
        val installedPkgs = installed.map { it.packageName }.toSet()
        val primaryPkg = FitnessAppRegistry.primaryPackage(installed)

        if (hasSteps) {
            val stepsResult = readStepsToday(
                client = client,
                start = startInstant,
                end = endInstant,
                installedPackages = installedPkgs,
                primaryPackage = primaryPkg,
            )
            out["stepsToday"] = stepsResult.count
            out["stepsDataSourceLine"] = stepsResult.dataSourceLine
            sourcesUsed.addAll(stepsResult.originPackages)
        }

        if (hasSleep) {
            val sleepResult = readSleepHours(
                client = client,
                start = sleepStart,
                end = endInstant,
                installedPackages = installedPkgs,
                primaryPackage = primaryPkg,
            )
            out["sleepHours"] = sleepResult.hours
            out["sleepDataSourceLine"] = sleepResult.dataSourceLine
            sourcesUsed.addAll(sleepResult.originPackages)
        }

        out["dataSourceLabels"] = sourcesUsed.map { FitnessAppRegistry.displayNameFor(it) }.distinct()

        val freshness = readFreshness(
            client = client,
            hasSteps = hasSteps,
            hasSleep = hasSleep,
            stepStart = startInstant,
            stepEnd = endInstant,
            sleepStart = sleepStart,
            sleepEnd = endInstant,
            installedPackages = installedPkgs,
        )
        val lastModified = freshness.lastModified
        if (lastModified != null) {
            out["lastDataUpdateMillis"] = lastModified.toEpochMilli()
            out["lastDataSourceLabel"] = freshness.lastOriginPackage?.let {
                FitnessAppRegistry.displayNameFor(it)
            }
        }
        out["dataMayBeStale"] = computeDataMayBeStale(
            now = now,
            freshness = freshness,
            hasInstalledFitness = installed.isNotEmpty(),
        )
        if (!hasSleep && hasSteps) {
            out["partialPermissionHint"] =
                "Steps are allowed. In Health Connect, also allow Sleep for this app, then refresh."
        }
        out
    }

    private suspend fun readFreshness(
        client: HealthConnectClient,
        hasSteps: Boolean,
        hasSleep: Boolean,
        stepStart: Instant,
        stepEnd: Instant,
        sleepStart: Instant,
        sleepEnd: Instant,
        installedPackages: Set<String>,
    ): FreshnessSnapshot {
        var latestFitness: Instant? = null
        var latestFitnessOrigin: String? = null
        var latestAny: Instant? = null
        var latestAnyOrigin: String? = null

        fun consider(modified: Instant, origin: String) {
            if (latestAny == null || modified.isAfter(latestAny)) {
                latestAny = modified
                latestAnyOrigin = origin
            }
            val isFitness = installedPackages.contains(origin) ||
                FitnessAppRegistry.isFitnessOrigin(origin)
            if (isFitness && (latestFitness == null || modified.isAfter(latestFitness))) {
                latestFitness = modified
                latestFitnessOrigin = origin
            }
        }

        if (hasSteps) {
            var request = ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(stepStart, stepEnd),
            )
            var response = client.readRecords(request)
            for (record in response.records) {
                consider(
                    record.metadata.lastModifiedTime,
                    record.metadata.dataOrigin.packageName,
                )
            }
            var pageToken = response.pageToken
            while (!pageToken.isNullOrEmpty()) {
                request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(stepStart, stepEnd),
                    pageToken = pageToken,
                )
                response = client.readRecords(request)
                for (record in response.records) {
                    consider(
                        record.metadata.lastModifiedTime,
                        record.metadata.dataOrigin.packageName,
                    )
                }
                pageToken = response.pageToken
            }
        }

        if (hasSleep) {
            var request = ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(sleepStart, sleepEnd),
            )
            var response = client.readRecords(request)
            for (session in response.records) {
                consider(
                    session.metadata.lastModifiedTime,
                    session.metadata.dataOrigin.packageName,
                )
            }
            var pageToken = response.pageToken
            while (!pageToken.isNullOrEmpty()) {
                request = ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(sleepStart, sleepEnd),
                    pageToken = pageToken,
                )
                response = client.readRecords(request)
                for (session in response.records) {
                    consider(
                        session.metadata.lastModifiedTime,
                        session.metadata.dataOrigin.packageName,
                    )
                }
                pageToken = response.pageToken
            }
        }

        return if (latestFitness != null) {
            FreshnessSnapshot(latestFitness, latestFitnessOrigin)
        } else {
            FreshnessSnapshot(latestAny, latestAnyOrigin)
        }
    }

    private fun computeDataMayBeStale(
        now: ZonedDateTime,
        freshness: FreshnessSnapshot,
        hasInstalledFitness: Boolean,
    ): Boolean {
        if (now.hour < STALE_CHECK_FROM_HOUR) return false
        val last = freshness.lastModified
        if (last == null) {
            return hasInstalledFitness
        }
        val hoursSince = Duration.between(last, now.toInstant()).toHours()
        return hoursSince >= STALE_AFTER_HOURS
    }

    private data class StepsReadResult(
        val count: Int,
        val originPackages: Set<String>,
        val dataSourceLine: String,
    )

    private fun healthConnectSourceLine(kind: String, packages: Set<String>): String {
        val labels = packages.map { FitnessAppRegistry.displayNameFor(it) }.distinct()
        return if (labels.isEmpty()) {
            "$kind from Health Connect · phone records · today"
        } else {
            "$kind from Health Connect · phone records · ${labels.joinToString(", ")}"
        }
    }

    /** Sum of raw [StepsRecord] counts per origin — not Health Connect aggregate API. */
    private suspend fun readStepsToday(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
        installedPackages: Set<String>,
        primaryPackage: String?,
    ): StepsReadResult {
        val byOrigin = readStepsTotalsByOrigin(client, start, end)

        val primaryTotal = primaryPackage?.let { byOrigin[it] } ?: 0L
        if (primaryTotal > 0L && primaryPackage != null) {
            return StepsReadResult(
                count = primaryTotal.toInt(),
                originPackages = setOf(primaryPackage),
                dataSourceLine = healthConnectSourceLine("Steps", setOf(primaryPackage)),
            )
        }

        val fitnessMaxEntry = byOrigin.entries
            .filter { (origin, _) -> originMatchesFilter(origin, OriginFilter.FitnessOnly(installedPackages)) }
            .maxByOrNull { it.value }
        if (fitnessMaxEntry != null && fitnessMaxEntry.value > 0L) {
            return StepsReadResult(
                count = fitnessMaxEntry.value.toInt(),
                originPackages = setOf(fitnessMaxEntry.key),
                dataSourceLine = healthConnectSourceLine("Steps", setOf(fitnessMaxEntry.key)),
            )
        }

        val allMaxEntry = byOrigin.maxByOrNull { it.value }
        if (allMaxEntry != null && allMaxEntry.value > 0L) {
            return StepsReadResult(
                count = allMaxEntry.value.toInt(),
                originPackages = setOf(allMaxEntry.key),
                dataSourceLine = healthConnectSourceLine("Steps", setOf(allMaxEntry.key)),
            )
        }

        return StepsReadResult(
            count = 0,
            originPackages = emptySet(),
            dataSourceLine = "No step records in Health Connect for today yet",
        )
    }

    private suspend fun readStepsTotalsByOrigin(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
    ): Map<String, Long> {
        val totals = linkedMapOf<String, Long>()
        fun process(records: List<StepsRecord>) {
            for (record in records) {
                val origin = record.metadata.dataOrigin.packageName
                totals[origin] = (totals[origin] ?: 0L) + record.count
            }
        }
        var request = ReadRecordsRequest(
            recordType = StepsRecord::class,
            timeRangeFilter = TimeRangeFilter.between(start, end),
        )
        var response = client.readRecords(request)
        process(response.records)
        var pageToken = response.pageToken
        while (!pageToken.isNullOrEmpty()) {
            request = ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                pageToken = pageToken,
            )
            response = client.readRecords(request)
            process(response.records)
            pageToken = response.pageToken
        }
        return totals
    }

    private data class SleepReadResult(
        val hours: Double?,
        val originPackages: Set<String>,
        val dataSourceLine: String,
    )

    /** Longest raw [SleepSessionRecord] (start/end on the record) — not aggregate API. */
    private suspend fun readSleepHours(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
        installedPackages: Set<String>,
        primaryPackage: String?,
    ): SleepReadResult {
        val sessions = readAllSleepSessions(client, start, end)
        val bestSession = pickBestSleepSession(sessions, installedPackages, primaryPackage, end)
            ?: return SleepReadResult(
                hours = null,
                originPackages = emptySet(),
                dataSourceLine = "No sleep session records in Health Connect for last night yet",
            )

        val minutes = sessionDurationMinutes(bestSession)
        if (minutes <= 0L) {
            return SleepReadResult(
                hours = null,
                originPackages = emptySet(),
                dataSourceLine = "Sleep record found but duration is empty — sync your fitness app",
            )
        }

        val origin = bestSession.metadata.dataOrigin.packageName
        return SleepReadResult(
            hours = minutes / 60.0,
            originPackages = setOf(origin),
            dataSourceLine = healthConnectSourceLine("Sleep", setOf(origin)),
        )
    }

    private fun sessionDurationMinutes(session: SleepSessionRecord): Long {
        val s = session.startTime
        val e = session.endTime
        if (!e.isAfter(s)) return 0L
        var minutes = Duration.between(s, e).toMinutes()
        if (minutes <= 0L && session.stages.isNotEmpty()) {
            minutes = session.stages.sumOf { stage ->
                Duration.between(stage.startTime, stage.endTime).toMinutes()
            }
        }
        return minutes.coerceAtLeast(0L)
    }

    private suspend fun readAllSleepSessions(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
    ): List<SleepSessionRecord> {
        val all = mutableListOf<SleepSessionRecord>()
        var request = ReadRecordsRequest(
            recordType = SleepSessionRecord::class,
            timeRangeFilter = TimeRangeFilter.between(start, end),
        )
        var response = client.readRecords(request)
        all.addAll(response.records)
        var pageToken = response.pageToken
        while (!pageToken.isNullOrEmpty()) {
            request = ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                pageToken = pageToken,
            )
            response = client.readRecords(request)
            all.addAll(response.records)
            pageToken = response.pageToken
        }
        return all
    }

    /**
     * Prefer the longest session that ended this morning (typical "last night"),
     * then fitness-origin sessions.
     */
    private fun pickBestSleepSession(
        sessions: List<SleepSessionRecord>,
        installedPackages: Set<String>,
        primaryPackage: String?,
        windowEnd: Instant,
    ): SleepSessionRecord? {
        if (sessions.isEmpty()) return null
        val zone = ZoneId.systemDefault()
        val endZdt = windowEnd.atZone(zone)
        val todayStart = endZdt.toLocalDate().atStartOfDay(zone).toInstant()

        fun score(session: SleepSessionRecord): Long {
            val origin = session.metadata.dataOrigin.packageName
            val duration = sessionDurationMinutes(session)
            var s = duration
            if (session.endTime.isAfter(todayStart) || session.endTime == todayStart) {
                s += 120L
            }
            if (primaryPackage != null && origin == primaryPackage) s += 60L
            if (installedPackages.contains(origin) || FitnessAppRegistry.isFitnessOrigin(origin)) {
                s += 30L
            }
            return s
        }

        return sessions.maxByOrNull { score(it) }
    }

    private fun originMatchesFilter(origin: String, filter: OriginFilter): Boolean {
        return when (filter) {
            is OriginFilter.All -> true
            is OriginFilter.Primary -> origin == filter.packageName
            is OriginFilter.FitnessOnly -> {
                if (filter.installedPackages.contains(origin)) return true
                FitnessAppRegistry.isFitnessOrigin(origin)
            }
        }
    }
}
