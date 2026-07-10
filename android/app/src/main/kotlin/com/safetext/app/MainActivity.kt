package com.safetext.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * SafeText's single native entry point.
 *
 * Exposes one platform channel, `com.safetext.app/security`, used by the
 * Settings screen to toggle `FLAG_SECURE` at runtime (blocking screenshots
 * and hiding the app's content from the recent-apps switcher) per the
 * "Block Screenshots" / "Hide App Previews" preferences.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.safetext.app/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecureFlag" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    if (enabled) {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "isRooted" -> result.success(isLikelyRooted())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Lightweight, best-effort root heuristic (checks for common su
     * binaries/paths). This is a UX signal for the Security Center, not a
     * hard security boundary — a determined attacker can hide root status
     * from userspace checks like this one.
     */
    private fun isLikelyRooted(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
            "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su",
            "/su/bin/su"
        )
        return paths.any { java.io.File(it).exists() }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
