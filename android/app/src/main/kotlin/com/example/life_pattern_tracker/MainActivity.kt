package com.example.life_pattern_tracker

import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream
import android.os.Process
import android.net.Uri
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import kotlinx.coroutines.launch
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

private fun queryForegroundStats(
    context: Context,
    startMillis: Long,
    endMillis: Long,
    excludePackage: String? = null
): Map<String, UsageStats> {
    val effectiveEnd = minOf(endMillis, System.currentTimeMillis())
    if (effectiveEnd <= startMillis) return emptyMap()

    val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val interval = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        UsageStatsManager.INTERVAL_BEST
    } else {
        UsageStatsManager.INTERVAL_DAILY
    }
    val stats = manager.queryUsageStats(interval, startMillis, effectiveEnd) ?: return emptyMap()

    val byPkg = LinkedHashMap<String, UsageStats>()
    for (stat in stats) {
        val pkg = stat.packageName ?: continue
        if (excludePackage != null && pkg == excludePackage) continue
        val foreground = stat.totalTimeInForeground
        if (foreground <= 0L) continue
        val existing = byPkg[pkg]
        if (existing == null || foreground > existing.totalTimeInForeground) {
            byPkg[pkg] = stat
        }
    }
    return byPkg
}

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "life_pattern_tracker/usage"
    companion object {
        const val LIMITS_PREF = "screen_time_limit_prefs"
        const val LIMITS_JSON_KEY = "limits_json_v1"
        const val WORK_NAME = "screen_time_limit_checker"
        const val CHANNEL_ID = "screen_time_limits"
    }

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
                    "openApplicationSettings" -> {
                        openApplicationSettings()
                        result.success(true)
                    }
                    "getApplicationLabel" -> {
                        result.success(getApplicationLabel())
                    }
                    "getUsageAccessHint" -> {
                        result.success(
                            AndroidCompat.usageAccessHint(
                                applicationContext,
                                getApplicationLabel()
                            )
                        )
                    }
                    "getHealthSyncHint" -> {
                        result.success(AndroidCompat.healthSyncHint())
                    }
                    "openHealthConnectApp" -> {
                        result.success(AndroidCompat.openHealthConnectApp(applicationContext))
                    }
                    "openHealthConnectPermissions" -> {
                        result.success(AndroidCompat.openHealthConnectPermissions(applicationContext))
                    }
                    "readHealthSummary" -> {
                        lifecycleScope.launch {
                            try {
                                result.success(HealthConnectBridge.readSummary(applicationContext))
                            } catch (e: Exception) {
                                result.error("HEALTH_READ_FAILED", e.message, null)
                            }
                        }
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
                    "listInstalledApps" -> result.success(listInstalledApps())
                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName.isNullOrBlank()) {
                            result.success(null)
                        } else {
                            result.success(getAppIconBytes(packageName))
                        }
                    }
                    "updateScreenTimeLimits" -> {
                        val limits = call.argument<List<*>>("limits")
                        result.success(updateScreenTimeLimits(limits))
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
        AndroidCompat.openFirstResolved(
            applicationContext,
            AndroidCompat.usageAccessIntents(applicationContext, packageName)
        )
    }

    private fun openApplicationSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        }
    }

    private fun getApplicationLabel(): String {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            "Life Pattern Tracker"
        }
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
        val packageManager = applicationContext.packageManager
        val byPkg = queryForegroundStats(
            applicationContext,
            startMillis,
            endMillis,
            applicationContext.packageName
        )

        val appList = mutableListOf<HashMap<String, Any>>()
        val hourly = IntArray(24) { 0 }
        var totalMinutes = 0

        for ((pkg, stat) in byPkg) {
            val timeMillis = stat.totalTimeInForeground
            if (timeMillis <= 0L) continue

            val minutes = (timeMillis / 60000L).toInt()
            if (minutes <= 0) continue
            totalMinutes += minutes

            val appName = try {
                val appInfo = packageManager.getApplicationInfo(pkg, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                pkg
            }

            val appInfo = try {
                packageManager.getApplicationInfo(pkg, 0)
            } catch (e: Exception) {
                null
            }

            val category = appCategory(appInfo)

            val appMap = hashMapOf<String, Any>(
                "appName" to appName,
                "packageName" to pkg,
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

    private fun listInstalledApps(): List<HashMap<String, Any>> {
        val packageManager = applicationContext.packageManager
        val selfPackage = applicationContext.packageName
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                launcherIntent,
                PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }

        val seen = HashSet<String>()
        val out = mutableListOf<HashMap<String, Any>>()

        for (resolveInfo in activities) {
            val pkg = resolveInfo.activityInfo?.packageName ?: continue
            if (pkg == selfPackage) continue
            if (!seen.add(pkg)) continue

            val appInfo = try {
                packageManager.getApplicationInfo(pkg, 0)
            } catch (_: Exception) {
                null
            }

            val name = try {
                if (appInfo != null) packageManager.getApplicationLabel(appInfo).toString() else pkg
            } catch (_: Exception) {
                pkg
            }

            out.add(
                hashMapOf(
                    "appName" to name,
                    "packageName" to pkg,
                    "category" to appCategory(appInfo)
                )
            )
        }

        out.sortBy { (it["appName"] as? String ?: "").lowercase() }
        return out
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = applicationContext.packageManager.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable, 128)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 92, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable, sizePx: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, sizePx, sizePx, true)
        }
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, sizePx, sizePx)
        drawable.draw(canvas)
        return bitmap
    }

    private fun updateScreenTimeLimits(limits: List<*>?): Boolean {
        val prefs = applicationContext.getSharedPreferences(LIMITS_PREF, Context.MODE_PRIVATE)
        val arr = JSONArray()
        if (limits != null) {
            for (entry in limits) {
                val map = entry as? Map<*, *> ?: continue
                val pkg = map["packageName"]?.toString().orEmpty()
                if (pkg.isBlank()) continue
                val obj = JSONObject()
                obj.put("packageName", pkg)
                obj.put("displayName", map["displayName"]?.toString().orEmpty())
                obj.put("limitMinutesPerDay", (map["limitMinutesPerDay"] as? Number)?.toInt() ?: 0)
                obj.put("notifyWhenExceeded", map["notifyWhenExceeded"] as? Boolean ?: true)
                arr.put(obj)
            }
        }
        prefs.edit().putString(LIMITS_JSON_KEY, arr.toString()).apply()
        scheduleOrCancelWorker(arr)
        return true
    }

    private fun scheduleOrCancelWorker(arr: JSONArray) {
        val hasActive = (0 until arr.length()).any {
            val item = arr.optJSONObject(it) ?: return@any false
            item.optBoolean("notifyWhenExceeded", true) &&
                item.optInt("limitMinutesPerDay", 0) > 0
        }
        val wm = WorkManager.getInstance(applicationContext)
        if (!hasActive) {
            wm.cancelUniqueWork(WORK_NAME)
            return
        }
        val req = PeriodicWorkRequestBuilder<ScreenTimeLimitWorker>(15, TimeUnit.MINUTES).build()
        wm.enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            req
        )
    }
}

class ScreenTimeLimitWorker(
    appContext: Context,
    params: WorkerParameters
) : Worker(appContext, params) {

    override fun doWork(): Result {
        if (!hasUsagePermission(applicationContext)) return Result.success()

        val prefs = applicationContext.getSharedPreferences(MainActivity.LIMITS_PREF, Context.MODE_PRIVATE)
        val limitsRaw = prefs.getString(MainActivity.LIMITS_JSON_KEY, "[]") ?: "[]"
        val limits = try {
            JSONArray(limitsRaw)
        } catch (_: Exception) {
            JSONArray()
        }
        if (limits.length() == 0) return Result.success()

        val startMillis = startOfDayMillis()
        val nowMillis = System.currentTimeMillis()
        val usageByPkg = queryUsageMinutes(applicationContext, startMillis, nowMillis)
        ensureChannel(applicationContext)

        for (i in 0 until limits.length()) {
            val item = limits.optJSONObject(i) ?: continue
            val notify = item.optBoolean("notifyWhenExceeded", true)
            val limitMinutes = item.optInt("limitMinutesPerDay", 0)
            val pkg = item.optString("packageName", "")
            val display = item.optString("displayName", pkg)
            if (!notify || limitMinutes <= 0 || pkg.isBlank()) continue

            val used = usageByPkg[pkg] ?: 0
            if (used < limitMinutes) continue

            val notifiedKey = "notified_${pkg}_${dayKey()}"
            if (prefs.getBoolean(notifiedKey, false)) continue

            notifyLimitReached(applicationContext, pkg, display, used, limitMinutes)
            prefs.edit().putBoolean(notifiedKey, true).apply()
        }
        return Result.success()
    }

    private fun queryUsageMinutes(
        context: Context,
        startMillis: Long,
        endMillis: Long
    ): Map<String, Int> {
        val out = HashMap<String, Int>()
        for ((pkg, stat) in queryForegroundStats(
            context,
            startMillis,
            endMillis,
            context.packageName
        )) {
            val minutes = (stat.totalTimeInForeground / 60000L).toInt()
            if (minutes > 0) out[pkg] = minutes
        }
        return out
    }

    private fun notifyLimitReached(
        context: Context,
        pkg: String,
        displayName: String,
        used: Int,
        limit: Int
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) return
        }
        val title = "Screen time limit reached"
        val text = "$displayName has reached $used minutes today (limit $limit minutes)."
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = launchIntent?.let {
            android.app.PendingIntent.getActivity(
                context,
                pkg.hashCode(),
                it,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
        }
        val n = NotificationCompat.Builder(context, MainActivity.CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        NotificationManagerCompat.from(context).notify(pkg.hashCode(), n)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(MainActivity.CHANNEL_ID)
        if (existing != null) return
        val ch = NotificationChannel(
            MainActivity.CHANNEL_ID,
            "Screen time limits",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts when app limits are exceeded"
        }
        manager.createNotificationChannel(ch)
    }

    private fun startOfDayMillis(): Long {
        val c = Calendar.getInstance()
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }

    private fun dayKey(): String {
        val c = Calendar.getInstance()
        return "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"
    }

    private fun hasUsagePermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
