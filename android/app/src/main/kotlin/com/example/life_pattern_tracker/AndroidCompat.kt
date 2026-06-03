package com.example.life_pattern_tracker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

/** OEM-aware helpers so usage access and settings work across Android devices. */
object AndroidCompat {

    fun usageAccessHint(context: Context, appLabel: String): String {
        val brand = (Build.BRAND ?: "").lowercase()
        val manufacturer = (Build.MANUFACTURER ?: "").lowercase()
        val key = if (manufacturer.isNotEmpty()) manufacturer else brand

        val path = when {
            key.contains("samsung") ->
                "Settings → Apps → ⋮ → Special access → Usage access"
            key.contains("xiaomi") || key.contains("redmi") || key.contains("poco") ->
                "Settings → Apps → Permissions → Special permissions → Usage access"
            key.contains("oppo") || key.contains("realme") || key.contains("oneplus") ->
                "Settings → Apps → Special app access → Usage access"
            key.contains("vivo") || key.contains("iqoo") ->
                "Settings → Apps → Special app access → Usage access"
            key.contains("huawei") || key.contains("honor") ->
                "Settings → Apps → Special access → Usage access"
            key.contains("motorola") || key.contains("lenovo") ->
                "Settings → Apps → Special app access → Usage access"
            key.contains("google") ->
                "Settings → Apps → Special app access → Usage access"
            key.contains("sony") ->
                "Settings → Apps → Special access → Usage access"
            else ->
                "Settings → search \"Usage access\" (or Special app access)"
        }
        return "In $path, find \"$appLabel\" and turn it On."
    }

    fun healthSyncHint(): String =
        "Connect your fitness app (Google Fit, Samsung Health, Fitbit, Garmin, etc.) " +
            "to Health Connect, then allow this app to read Steps and Sleep."

    fun usageAccessIntents(context: Context, packageName: String): List<Intent> {
        val pm = context.packageManager
        val out = LinkedHashSet<Intent>()

        fun add(intent: Intent) {
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            if (intent.resolveActivity(pm) != null) {
                out.add(intent)
            }
        }

        add(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        add(
            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        )
        add(Intent("android.settings.USAGE_ACCESS_SETTINGS"))

        // OEM-specific editors (only if installed).
        add(
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.PermissionsEditorActivity"
                )
                putExtra("extra_pkgname", packageName)
            }
        )
        add(
            Intent().apply {
                setClassName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.AppPermissionsEditorActivity"
                )
                putExtra("extra_pkgname", packageName)
            }
        )
        add(
            Intent().apply {
                setClassName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.PermissionManagerActivity"
                )
            }
        )
        add(
            Intent().apply {
                setClassName(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.PermissionManagerActivity"
                )
            }
        )
        add(
            Intent().apply {
                setClassName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity"
                )
                putExtra("packagename", packageName)
            }
        )
        add(
            Intent().apply {
                setClassName(
                    "com.huawei.systemmanager",
                    "com.huawei.permissionmanager.ui.MainActivity"
                )
            }
        )

        add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        )

        return out.toList()
    }

    fun openFirstResolved(context: Context, intents: List<Intent>): Boolean {
        for (intent in intents) {
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                return true
            }
        }
        return false
    }

    fun openHealthConnectApp(context: Context): Boolean {
        val pm = context.packageManager
        val pkg = "com.google.android.apps.healthdata"
        val launch = pm.getLaunchIntentForPackage(pkg) ?: return false
        launch.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(launch)
        return true
    }

    /** Opens Health Connect permission UI for this app (all Android versions). */
    fun healthConnectPermissionIntents(context: Context): List<Intent> {
        val pkg = context.packageName
        val out = LinkedHashSet<Intent>()

        fun add(intent: Intent) {
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            if (intent.resolveActivity(context.packageManager) != null) {
                out.add(intent)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            add(
                Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                    putExtra(Intent.EXTRA_PACKAGE_NAME, pkg)
                }
            )
        }
        add(Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"))
        add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", pkg, null)
            }
        )
        return out.toList()
    }

    fun openHealthConnectPermissions(context: Context): Boolean {
        if (openFirstResolved(context, healthConnectPermissionIntents(context))) return true
        return openHealthConnectApp(context)
    }
}
