package com.example.life_pattern_tracker

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

/** Reads Health Connect directly (works when the Flutter health plugin SDK check is too strict). */
object HealthConnectBridge {

    fun sdkStatus(context: Context): Int =
        HealthConnectClient.getSdkStatus(context)

    fun isSdkUsable(status: Int): Boolean =
        status == HealthConnectClient.SDK_AVAILABLE ||
            status == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED

    suspend fun readSummary(context: Context): Map<String, Any?> = withContext(Dispatchers.IO) {
        val status = sdkStatus(context)
        val out = hashMapOf<String, Any?>(
            "sdkStatus" to status,
            "permissionsGranted" to false,
            "stepsToday" to 0,
            "sleepHours" to null,
            "error" to null,
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

        if (hasSteps) {
            try {
                val response = client.aggregate(
                    AggregateRequest(
                        metrics = setOf(StepsRecord.COUNT_TOTAL),
                        timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant),
                    )
                )
                val steps = response[StepsRecord.COUNT_TOTAL]?.toLong() ?: 0L
                out["stepsToday"] = steps.toInt()
            } catch (e: Exception) {
                out["stepsToday"] = readStepsFromRecords(client, startInstant, endInstant)
            }
        }

        if (hasSleep) {
            val sleepStart = startOfDay.minusHours(24).toInstant()
            out["sleepHours"] = readSleepHours(client, sleepStart, endInstant)
        }

        out
    }

    private suspend fun readStepsFromRecords(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
    ): Int {
        var total = 0L
        val request = ReadRecordsRequest(
            recordType = StepsRecord::class,
            timeRangeFilter = TimeRangeFilter.between(start, end),
        )
        var response = client.readRecords(request)
        var pageToken = response.pageToken
        for (record in response.records) {
            total += record.count
        }
        while (!pageToken.isNullOrEmpty()) {
            val next = ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                pageToken = pageToken,
            )
            response = client.readRecords(next)
            pageToken = response.pageToken
            for (record in response.records) {
                total += record.count
            }
        }
        return total.toInt()
    }

    private suspend fun readSleepHours(
        client: HealthConnectClient,
        start: Instant,
        end: Instant,
    ): Double? {
        val request = ReadRecordsRequest(
            recordType = SleepSessionRecord::class,
            timeRangeFilter = TimeRangeFilter.between(start, end),
        )
        var minutes = 0L
        var response = client.readRecords(request)
        var pageToken = response.pageToken
        fun addSessions(records: List<SleepSessionRecord>) {
            for (session in records) {
                val s = session.startTime
                val e = session.endTime
                if (e.isAfter(s)) {
                    minutes += java.time.Duration.between(s, e).toMinutes()
                }
            }
        }
        addSessions(response.records)
        while (!pageToken.isNullOrEmpty()) {
            val next = ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                pageToken = pageToken,
            )
            response = client.readRecords(next)
            pageToken = response.pageToken
            addSessions(response.records)
        }
        if (minutes <= 0L) return null
        return minutes / 60.0
    }
}
