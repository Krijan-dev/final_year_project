package com.example.life_pattern_tracker

import android.content.Context
import android.content.pm.PackageManager

/** Known fitness / smartwatch apps that sync steps and sleep into Health Connect. */
object FitnessAppRegistry {

    data class FitnessApp(val packageName: String, val displayName: String)

    /** Higher priority = preferred when multiple apps are installed. */
    private val KNOWN_APPS: List<FitnessApp> = listOf(
        FitnessApp("com.sec.android.app.shealth", "Samsung Health"),
        FitnessApp("com.samsung.android.app.health", "Samsung Health"),
        FitnessApp("com.samsung.android.wearable.health", "Galaxy Wearable"),
        FitnessApp("com.google.android.apps.fitness", "Google Fit"),
        FitnessApp("com.google.android.apps.wear.companion", "Wear OS"),
        FitnessApp("com.fitbit.FitbitMobile", "Fitbit"),
        FitnessApp("com.garmin.android.apps.connectmobile", "Garmin Connect"),
        FitnessApp("com.huawei.health", "Huawei Health"),
        FitnessApp("com.mi.health", "Mi Fitness"),
        FitnessApp("com.xiaomi.wearable", "Mi Wearable"),
        FitnessApp("com.ouraring.oura", "Oura"),
        FitnessApp("com.withings.wiscale2", "Withings"),
        FitnessApp("com.polar.flowservice", "Polar Flow"),
        FitnessApp("com.strava", "Strava"),
        FitnessApp("com.suunto.mobile", "Suunto"),
        FitnessApp("com.whoop.android", "WHOOP"),
        FitnessApp("com.nike.plusgps", "Nike Run Club"),
        FitnessApp("com.myfitnesspal.android", "MyFitnessPal"),
        FitnessApp("com.fossil.wearables.fossil", "Fossil Smartwatches"),
        FitnessApp("com.heytap.health", "OHealth"),
        FitnessApp("com.oneplus.health", "OnePlus Health"),
    )

    private val KNOWN_PACKAGES: Set<String> = KNOWN_APPS.map { it.packageName }.toSet()

    private val PRIORITY_ORDER: List<String> = KNOWN_APPS.map { it.packageName }

    private val FITNESS_PACKAGE_PREFIXES = listOf(
        "com.sec.android.app.shealth",
        "com.samsung.android",
        "com.google.android.apps.fitness",
        "com.google.android.apps.wear",
        "com.fitbit.",
        "com.garmin.",
        "com.huawei.health",
        "com.mi.health",
        "com.xiaomi.wearable",
        "com.ouraring.",
        "com.withings.",
        "com.polar.",
        "com.strava",
        "com.suunto.",
        "com.whoop.",
    )

    fun displayNameFor(packageName: String): String {
        KNOWN_APPS.firstOrNull { it.packageName == packageName }?.displayName?.let { return it }
        return packageName.substringAfterLast('.').replaceFirstChar { c ->
            if (c.isLowerCase()) c.titlecase() else c.toString()
        }
    }

    fun isFitnessOrigin(packageName: String): Boolean {
        if (KNOWN_PACKAGES.contains(packageName)) return true
        return FITNESS_PACKAGE_PREFIXES.any { packageName.startsWith(it) }
    }

    fun getInstalled(context: Context): List<FitnessApp> {
        val pm = context.packageManager
        return KNOWN_APPS.filter { app ->
            try {
                pm.getPackageInfo(app.packageName, 0)
                true
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    fun primaryPackage(installed: List<FitnessApp>): String? {
        for (pkg in PRIORITY_ORDER) {
            val match = installed.firstOrNull { it.packageName == pkg }
            if (match != null) return match.packageName
        }
        return installed.firstOrNull()?.packageName
    }
}
