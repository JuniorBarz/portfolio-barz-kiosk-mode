package com.barz.kioskmode

import android.content.Context
import android.content.Intent

class AppLauncher(private val context: Context) {
    fun launch(packageName: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: throw IllegalStateException("No launcher intent for $packageName.")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}

