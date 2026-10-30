package com.barz.kioskmode

import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var runtimeStore: KioskRuntimeStore
    private lateinit var systemUi: SystemUiController
    private lateinit var launcher: AppLauncher

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initializeNativeControllers()
        KioskMethodChannel(this, flutterEngine).register()
    }

    override fun onResume() {
        super.onResume()
        initializeNativeControllers()
        systemUi.applyImmersiveMode()
        relaunchTargetIfNeeded()
    }

    override fun onPause() {
        handler.removeCallbacksAndMessages(null)
        super.onPause()
    }

    private fun initializeNativeControllers() {
        if (!::runtimeStore.isInitialized) {
            runtimeStore = KioskRuntimeStore(this)
            systemUi = SystemUiController(this)
            launcher = AppLauncher(this)
        }
    }

    private fun relaunchTargetIfNeeded() {
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({
            val target = runtimeStore.targetPackage
            if (runtimeStore.active && !runtimeStore.unlockInProgress && !target.isNullOrBlank()) {
                startService(
                    Intent(this, KioskWatchdogService::class.java)
                        .putExtra("targetPackage", target)
                )
                launcher.launch(target)
            }
        }, 350L)
    }
}

