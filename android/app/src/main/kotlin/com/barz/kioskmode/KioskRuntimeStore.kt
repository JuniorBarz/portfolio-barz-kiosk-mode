package com.barz.kioskmode

import android.content.Context

class KioskRuntimeStore(context: Context) {
    private val prefs = context.getSharedPreferences("barz_kiosk_config", Context.MODE_PRIVATE)

    var active: Boolean
        get() = prefs.getBoolean("kiosk.active", false)
        set(value) {
            prefs.edit().putBoolean("kiosk.active", value).apply()
        }

    var targetPackage: String?
        get() = prefs.getString("kiosk.targetPackage", null)
        set(value) {
            val editor = prefs.edit()
            if (value == null) {
                editor.remove("kiosk.targetPackage")
            } else {
                editor.putString("kiosk.targetPackage", value)
            }
            editor.apply()
        }

    var unlockInProgress: Boolean
        get() = prefs.getBoolean("kiosk.unlockInProgress", false)
        set(value) {
            prefs.edit().putBoolean("kiosk.unlockInProgress", value).apply()
        }

    var pendingUnlockRequest: Boolean
        get() = prefs.getBoolean("kiosk.pendingUnlockRequest", false)
        set(value) {
            prefs.edit().putBoolean("kiosk.pendingUnlockRequest", value).apply()
        }

    var overlayDebugEnabled: Boolean
        get() = prefs.getBoolean("kiosk.overlayDebugEnabled", true)
        set(value) {
            prefs.edit().putBoolean("kiosk.overlayDebugEnabled", value).apply()
        }
}

