package com.example.life_pattern_tracker

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val channelName = "life_pattern_tracker/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "hasUsagePermission" -> result.success(hasUsagePermission())
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(true)
                    }
                    "getUsageStats" -> {
                        if (!hasUsagePermission()) {
                            result.error("PERMISSION_DENIED", "Usage access is not granted", null)
                            return@setMethodCallHandler
                        }
                        val startMillis = call.argument<Number>("startMillis")?.toLong() ?: startOfDayMillis()
                        val endMillis = call.argument<Number>("endMillis")?.toLong() ?: System.currentTimeMillis()
                        result.success(getUsageStats(startMillis, endMillis))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun startOfDayMillis(): Long {
        val c = Calendar.getInstance()
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }

    private fun getUsageStats(startMillis: Long, endMillis: Long): HashMap<String, Any> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = applicationContext.packageManager
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startMillis,
            endMillis
        )

        val appList = mutableListOf<HashMap<String, Any>>()
        val hourly = IntArray(24) { 0 }
        var totalMinutes = 0

        for (stat in stats) {
            val timeMillis = stat.totalTimeInForeground
            if (timeMillis <= 0L || stat.packageName == packageName) continue

            val minutes = (timeMillis / 60000L).toInt()
            if (minutes <= 0) continue
            totalMinutes += minutes

            val appName = try {
                val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                stat.packageName
            }

            val appInfo = try {
                packageManager.getApplicationInfo(stat.packageName, 0)
            } catch (e: Exception) {
                null
            }

            val category = appCategory(appInfo)

            val appMap = hashMapOf<String, Any>(
                "appName" to appName,
                "packageName" to stat.packageName,
                "usageTime" to minutes,
                "lastUsed" to stat.lastTimeUsed,
                "category" to category
            )
            appList.add(appMap)

            if (stat.lastTimeUsed > 0L) {
                val cal = Calendar.getInstance()
                cal.timeInMillis = stat.lastTimeUsed
                val hour = cal.get(Calendar.HOUR_OF_DAY).coerceIn(0, 23)
                hourly[hour] += minutes
            }
        }

        appList.sortByDescending { (it["usageTime"] as Int) }

        return hashMapOf(
            "date" to java.text.SimpleDateFormat("yyyy-MM-dd'T'00:00:00", java.util.Locale.US)
                .format(java.util.Date(startMillis)),
            "totalScreenTime" to totalMinutes,
            "hourlyUsageMinutes" to hourly.toList(),
            "apps" to appList
        )
    }

    private fun appCategory(appInfo: ApplicationInfo?): String {
        if (appInfo == null) return "other"
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "other"
        return when (appInfo.category) {
            ApplicationInfo.CATEGORY_AUDIO -> "audio"
            ApplicationInfo.CATEGORY_GAME -> "game"
            ApplicationInfo.CATEGORY_IMAGE -> "image"
            ApplicationInfo.CATEGORY_MAPS -> "maps"
            ApplicationInfo.CATEGORY_NEWS -> "news"
            ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
            ApplicationInfo.CATEGORY_SOCIAL -> "social"
            ApplicationInfo.CATEGORY_VIDEO -> "video"
            else -> "other"
        }
    }
}
