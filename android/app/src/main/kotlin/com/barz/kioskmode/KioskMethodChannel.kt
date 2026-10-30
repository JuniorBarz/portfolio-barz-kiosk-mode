package com.barz.kioskmode

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class KioskMethodChannel(
    private val activity: Activity,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kiosk_manager")
    private val apps = InstalledAppsProvider(activity)
    private val systemUi = SystemUiController(activity)
    private val security = KioskSecurityController(activity)
    private val launcher = AppLauncher(activity)
    private val prefs = activity.getSharedPreferences("barz_kiosk_config", Context.MODE_PRIVATE)
    private val runtimeStore = KioskRuntimeStore(activity)

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getStatus" -> result.success(NativeResult.ok(statusMap()))
                "listInstalledApps" -> result.success(NativeResult.ok(apps.listLaunchableApps()))
                "isLaunchable" -> {
                    val packageName = call.argument<String>("packageName")
                    result.success(NativeResult.ok(packageName != null && apps.isLaunchable(packageName)))
                }
                "startKiosk" -> startKiosk(call, result)
                "stopKiosk" -> stopKiosk(result)
                "beginUnlock" -> {
                    runtimeStore.unlockInProgress = true
                    result.success(NativeResult.ok(true))
                }
                "endUnlock" -> {
                    runtimeStore.unlockInProgress = false
                    activity.startService(
                        Intent(activity, SecretTapOverlayService::class.java)
                            .setAction(SecretTapOverlayService.ACTION_RESET)
                    )
                    result.success(NativeResult.ok(true))
                }
                "consumeUnlockRequest" -> {
                    val pending = runtimeStore.pendingUnlockRequest
                    runtimeStore.pendingUnlockRequest = false
                    result.success(NativeResult.ok(pending))
                }
                "openUsageAccessSettings" -> openSettings(security.usageAccessSettingsIntent(), result)
                "openOverlaySettings" -> openSettings(security.overlaySettingsIntent(), result)
                "openHomeSettings" -> openSettings(security.homeSettingsIntent(), result)
                "openAccessibilitySettings" -> openSettings(security.accessibilitySettingsIntent(), result)
                "setSecretTapOverlayDebug" -> {
                    runtimeStore.overlayDebugEnabled = call.argument<Boolean>("enabled") ?: true
                    activity.startService(
                        Intent(activity, SecretTapOverlayService::class.java)
                            .setAction(SecretTapOverlayService.ACTION_REFRESH)
                    )
                    result.success(NativeResult.ok(true))
                }
                "loadSelectedApp" -> result.success(NativeResult.ok(loadSelectedApp()))
                "saveSelectedApp" -> saveSelectedApp(call, result)
                "clearSelectedApp" -> {
                    prefs.edit()
                        .remove("selected.packageName")
                        .remove("selected.label")
                        .remove("selected.versionCode")
                        .remove("selected.versionName")
                        .apply()
                    result.success(NativeResult.ok(true))
                }
                "loadPinRecord" -> result.success(NativeResult.ok(loadPinRecord()))
                "savePinRecord" -> savePinRecord(call, result)
                "requiresPinChange" -> result.success(
                    NativeResult.ok(prefs.getBoolean("pin.requiresChange", true))
                )
                "setRequiresPinChange" -> {
                    prefs.edit()
                        .putBoolean("pin.requiresChange", call.argument<Boolean>("value") ?: true)
                        .apply()
                    result.success(NativeResult.ok(true))
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.success(NativeResult.fail(error.message ?: error.javaClass.simpleName))
        }
    }

    private fun statusMap(): Map<String, Any> {
        return mapOf(
            "isDeviceOwner" to false,
            "hasUsageStatsPermission" to security.hasUsageStatsPermission(),
            "hasOverlayPermission" to security.hasOverlayPermission(),
            "isOverlayDebugEnabled" to runtimeStore.overlayDebugEnabled,
            "isDefaultLauncher" to security.isDefaultLauncher(),
            "isAccessibilityEnabled" to security.isAccessibilityEnabled()
        )
    }

    private fun startKiosk(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.success(NativeResult.fail("Missing packageName."))
            return
        }
        if (!apps.isLaunchable(packageName)) {
            result.success(NativeResult.fail("Target app is not launchable."))
            return
        }
        if (!security.hasUsageStatsPermission()) {
            activity.startActivity(security.usageAccessSettingsIntent())
            result.success(NativeResult.fail("UsageStats permission is required for lightweight kiosk."))
            return
        }
        if (!security.hasOverlayPermission()) {
            activity.startActivity(security.overlaySettingsIntent())
            result.success(NativeResult.fail("Overlay permission is required for the secret tap unlock."))
            return
        }
        if (!security.isDefaultLauncher()) {
            activity.startActivity(security.homeSettingsIntent())
            result.success(NativeResult.fail("Set Barz Kiosk Mode as the default launcher."))
            return
        }

        systemUi.applyImmersiveMode()
        runtimeStore.active = true
        runtimeStore.targetPackage = packageName
        runtimeStore.unlockInProgress = false
        runtimeStore.pendingUnlockRequest = false
        activity.startService(Intent(activity, SecretTapOverlayService::class.java))
        launcher.launch(packageName)
        activity.startService(
            Intent(activity, KioskWatchdogService::class.java)
                .putExtra("targetPackage", packageName)
        )
        result.success(NativeResult.ok(true))
    }

    private fun stopKiosk(result: MethodChannel.Result) {
        runtimeStore.active = false
        runtimeStore.targetPackage = null
        runtimeStore.unlockInProgress = false
        runtimeStore.pendingUnlockRequest = false
        activity.stopService(Intent(activity, SecretTapOverlayService::class.java))
        activity.stopService(Intent(activity, KioskWatchdogService::class.java))
        systemUi.clearImmersiveMode()
        result.success(NativeResult.ok(true))
    }

    private fun openSettings(intent: Intent, result: MethodChannel.Result) {
        activity.startActivity(intent)
        result.success(NativeResult.ok(true))
    }

    private fun loadSelectedApp(): Map<String, Any?>? {
        val packageName = prefs.getString("selected.packageName", null) ?: return null
        return mapOf(
            "packageName" to packageName,
            "label" to (prefs.getString("selected.label", null) ?: packageName),
            "versionCode" to prefs.getLong("selected.versionCode", 0L),
            "versionName" to (prefs.getString("selected.versionName", null) ?: "")
        )
    }

    private fun saveSelectedApp(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        val label = call.argument<String>("label")
        val versionName = call.argument<String>("versionName")
        val versionCode = call.argument<Number>("versionCode")?.toLong()
        if (packageName.isNullOrBlank() || label == null || versionCode == null || versionName == null) {
            result.success(NativeResult.fail("Invalid selected app payload."))
            return
        }
        prefs.edit()
            .putString("selected.packageName", packageName)
            .putString("selected.label", label)
            .putLong("selected.versionCode", versionCode)
            .putString("selected.versionName", versionName)
            .apply()
        result.success(NativeResult.ok(true))
    }

    private fun loadPinRecord(): Map<String, Any?>? {
        val hash = prefs.getString("pin.hash", null) ?: return null
        val salt = prefs.getString("pin.salt", null) ?: return null
        return mapOf(
            "hash" to hash,
            "salt" to salt,
            "version" to prefs.getInt("pin.version", 1)
        )
    }

    private fun savePinRecord(call: MethodCall, result: MethodChannel.Result) {
        val hash = call.argument<String>("hash")
        val salt = call.argument<String>("salt")
        val version = call.argument<Int>("version")
        if (hash.isNullOrBlank() || salt.isNullOrBlank() || version == null) {
            result.success(NativeResult.fail("Invalid PIN record payload."))
            return
        }
        prefs.edit()
            .putString("pin.hash", hash)
            .putString("pin.salt", salt)
            .putInt("pin.version", version)
            .apply()
        result.success(NativeResult.ok(true))
    }
}

