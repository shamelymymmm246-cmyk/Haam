// هذا الملف احتياطي — بعد flutter create، انسخ محتواه إلى:
// android/app/src/main/kotlin/com/haam/security/MainActivity.kt

package com.haam.security

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val DNS_CHANNEL = "com.haam.security/dns"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DNS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPrivateDnsMode"      -> result.success(getPrivateDnsMode())
                    "getPrivateDnsHostname"  -> result.success(getPrivateDnsHostname())
                    "openPrivateDnsSettings" -> {
                        openPrivateDnsSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // قراءة وضع Private DNS من Settings.Global (Android 9+ / API 28+)
    // لا تحتاج صلاحية خاصة — قراءة فقط
    private fun getPrivateDnsMode(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return "unknown"
        return try {
            Settings.Global.getString(contentResolver, "private_dns_mode") ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
    }

    private fun getPrivateDnsHostname(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        return try {
            Settings.Global.getString(contentResolver, "private_dns_specifier")
        } catch (_: Exception) {
            null
        }
    }

    // فتح شاشة إعدادات Private DNS (Android 9+)
    private fun openPrivateDnsSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.ACTION_PRIVATE_DNS_SETTINGS)
        } else {
            Intent(Settings.ACTION_WIRELESS_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
