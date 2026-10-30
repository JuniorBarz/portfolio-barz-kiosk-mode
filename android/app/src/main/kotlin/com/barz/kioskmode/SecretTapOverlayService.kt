package com.barz.kioskmode

import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager

class SecretTapOverlayService : Service() {
    companion object {
        const val ACTION_RESET = "com.barz.kioskmode.action.RESET_SECRET_TAP"
        const val ACTION_REFRESH = "com.barz.kioskmode.action.REFRESH_SECRET_TAP"
        const val REQUIRED_TAPS = 7
        const val TAP_WINDOW_MS = 3000L
        const val TAP_ZONE_WIDTH_DP = 220
        const val TAP_ZONE_HEIGHT_DP = 160
    }

    private lateinit var runtimeStore: KioskRuntimeStore
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var firstTapAtMs: Long = 0L
    private var tapCount = 0
    private var triggered = false

    override fun onCreate() {
        super.onCreate()
        runtimeStore = KioskRuntimeStore(this)
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        installOverlay()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_RESET) {
            resetDetector()
        } else if (intent?.action == ACTION_REFRESH) {
            refreshOverlay()
        }
        if (overlayView == null) {
            installOverlay()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun installOverlay() {
        if (overlayView != null) return

        val view = View(this).apply {
            setBackgroundColor(overlayColor())
            setOnTouchListener { _, event ->
                if (event.action == MotionEvent.ACTION_UP) {
                    registerTap(SystemClock.elapsedRealtime())
                }
                true
            }
        }

        val width = (TAP_ZONE_WIDTH_DP * resources.displayMetrics.density).toInt()
        val height = (TAP_ZONE_HEIGHT_DP * resources.displayMetrics.density).toInt()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            width,
            height,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
        }

        windowManager?.addView(view, params)
        overlayView = view
    }

    private fun removeOverlay() {
        val view = overlayView ?: return
        windowManager?.removeView(view)
        overlayView = null
    }

    private fun registerTap(nowMs: Long) {
        if (!runtimeStore.active || triggered || runtimeStore.unlockInProgress) return

        if (firstTapAtMs == 0L || nowMs - firstTapAtMs > TAP_WINDOW_MS) {
            firstTapAtMs = nowMs
            tapCount = 1
            return
        }

        tapCount++
        if (tapCount >= REQUIRED_TAPS) {
            triggered = true
            runtimeStore.unlockInProgress = true
            runtimeStore.pendingUnlockRequest = true
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("openPin", true)
                }
            )
        }
    }

    private fun resetDetector() {
        firstTapAtMs = 0L
        tapCount = 0
        triggered = false
    }

    private fun refreshOverlay() {
        overlayView?.setBackgroundColor(overlayColor())
    }

    private fun overlayColor(): Int {
        return if (runtimeStore.overlayDebugEnabled) {
            Color.argb(72, 0, 180, 255)
        } else {
            Color.TRANSPARENT
        }
    }
}

