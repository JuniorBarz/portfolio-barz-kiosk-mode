package com.barz.kioskmode

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

class BootFlowController(private val context: Context) {
    fun openLauncherAfterDelay() {
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("fromBoot", true)
            }
            context.startActivity(intent)
        }, 1500L)
    }
}

