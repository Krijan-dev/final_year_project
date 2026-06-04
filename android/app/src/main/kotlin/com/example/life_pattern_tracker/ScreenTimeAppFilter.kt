package com.example.life_pattern_tracker

/**
 * Which apps belong in a Digital Wellbeing–style screen time list.
 * Health / fitness / Health Connect are tracked separately, not as screen time.
 */
object ScreenTimeAppFilter {

    private val ALWAYS_EXCLUDED = setOf(
        "com.google.android.apps.healthdata",
        "com.samsung.android.forest",
        "com.android.settings",
        "com.google.android.settings.intelligence",
    )

    fun isExcluded(packageName: String, selfPackage: String?): Boolean {
        if (packageName.isBlank()) return true
        if (selfPackage != null && packageName == selfPackage) return true
        if (ALWAYS_EXCLUDED.contains(packageName)) return true
        if (FitnessAppRegistry.isFitnessOrigin(packageName)) return true
        return false
    }

}
