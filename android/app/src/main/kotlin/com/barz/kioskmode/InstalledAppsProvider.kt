package com.barz.kioskmode

import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build

class InstalledAppsProvider(private val context: Context) {
    private val packageManager: PackageManager = context.packageManager

    fun listLaunchableApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return packageManager.queryIntentActivities(intent, 0)
            .mapNotNull { resolveInfo ->
                val packageName = resolveInfo.activityInfo?.packageName ?: return@mapNotNull null
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                mapOf(
                    "packageName" to packageName,
                    "label" to resolveInfo.loadLabel(packageManager).toString(),
                    "versionCode" to versionCode(packageInfo),
                    "versionName" to (packageInfo.versionName ?: "")
                )
            }
            .sortedBy { it["label"] as String }
    }

    fun isLaunchable(packageName: String): Boolean {
        return packageManager.getLaunchIntentForPackage(packageName) != null
    }

    private fun versionCode(packageInfo: PackageInfo): Long {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }
    }
}

