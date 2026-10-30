package com.barz.kioskmode

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class KioskWatchdogService : Service() {
    private companion object {
        const val CHECK_INTERVAL_MS = 1000L
        const val RELAUNCH_TOLERANCE_MS = 750L
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var monitor: ForegroundAppMonitor
    private lateinit var recovery: KioskRecoveryController
    private lateinit var runtimeStore: KioskRuntimeStore
    private var targetPackage: String? = null
    private var active = false
    private var mismatchSinceMs: Long? = null

    private val tick = object : Runnable {
        override fun run() {
            val target = targetPackage
            if (active && target != null) {
                val current = monitor.currentForegroundPackage()
                if (runtimeStore.unlockInProgress) {
                    mismatchSinceMs = null
                } else if (current != null && current != target) {
                    val now = monitor.monotonicNowMs()
                    val mismatchSince = mismatchSinceMs ?: now.also { mismatchSinceMs = it }
                    if (now - mismatchSince >= RELAUNCH_TOLERANCE_MS) {
                        if (recovery.canRelaunch(now)) {
                            recovery.recordRelaunch(now)
                            mismatchSinceMs = null
                            AppLauncher(this@KioskWatchdogService).launch(target)
                        } else {
                            active = false
                            runtimeStore.active = false
                        }
                    }
                } else {
                    mismatchSinceMs = null
                }
                handler.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        monitor = ForegroundAppMonitor(this)
        recovery = KioskRecoveryController()
        runtimeStore = KioskRuntimeStore(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        targetPackage = intent?.getStringExtra("targetPackage") ?: runtimeStore.targetPackage
        active = runtimeStore.active && !targetPackage.isNullOrBlank()
        if (active) {
            startService(Intent(this, SecretTapOverlayService::class.java))
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        active = false
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

