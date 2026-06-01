package com.haam.security

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    // المرحلة 6 — منع لقطات الشاشة وحماية المحتوى
    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    private val DNS_CHANNEL       = "com.haam.security/dns"
    private val NETWORK_CHANNEL   = "com.haam.security/network"
    private val APPS_CHANNEL      = "com.haam.security/apps"
    private val INTEGRITY_CHANNEL = "com.haam.security/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 1 — DNS (المرحلة 1)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DNS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPrivateDnsMode"      -> result.success(getPrivateDnsMode())
                    "getPrivateDnsHostname"  -> result.success(getPrivateDnsHostname())
                    "openPrivateDnsSettings" -> { openPrivateDnsSettings(); result.success(null) }
                    else                     -> result.notImplemented()
                }
            }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 2 — Network (المرحلة 2)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWifiInfo" -> result.success(getWifiInfo())
                    else          -> result.notImplemented()
                }
            }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 3 — Apps (المرحلة 2)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        // نُشغّل في thread منفصل لأن PackageManager بطيء
                        Thread {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 4 — Integrity (المرحلة 2)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEGRITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkIntegrity" -> result.success(checkIntegrity())
                    else             -> result.notImplemented()
                }
            }
    }

    // ════════════════════════════════════
    // DNS — قراءة إعداد Private DNS (API 28+)
    // ════════════════════════════════════

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

    private fun openPrivateDnsSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // ACTION_PRIVATE_DNS_SETTINGS ليس ثابتاً عاماً في SDK — نستخدم قيمته النصية
            Intent("android.settings.PRIVATE_DNS_SETTINGS")
        } else {
            Intent(Settings.ACTION_WIRELESS_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // ════════════════════════════════════
    // Network — معلومات الواي فاي
    // ════════════════════════════════════

    @SuppressLint("MissingPermission", "HardwareIds")
    private fun getWifiInfo(): Map<String, Any?> {
        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return emptyWifiMap()

        if (!wm.isWifiEnabled) return emptyWifiMap()

        val wifiInfo = wm.connectionInfo ?: return emptyWifiMap()
        val dhcpInfo = wm.dhcpInfo

        val hasLocation = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        // SSID يتطلب إذن الموقع منذ Android 8.1
        val ssid = if (hasLocation) {
            wifiInfo.ssid?.let { raw ->
                if (raw == "<unknown ssid>" || raw == WifiManager.UNKNOWN_SSID) null
                else raw.trim('"')
            }
        } else null

        // BSSID مجهوم دون إذن موقع (تُعيد Android "02:00:00:00:00:00")
        val bssid = if (hasLocation) {
            wifiInfo.bssid?.takeIf { it != "02:00:00:00:00:00" }
        } else null

        val signal    = wifiInfo.rssi.takeIf { it > -127 && it != Int.MIN_VALUE }
        val frequency = wifiInfo.frequency.takeIf { it > 0 }

        val gateway    = dhcpInfo?.gateway?.takeIf { it != 0 }?.let { intToIp(it) }
        val subnetMask = dhcpInfo?.netmask?.takeIf { it != 0 }?.let { intToIp(it) }

        val encryptionType = getEncryptionType(wm, wifiInfo.bssid, hasLocation)
        val isOpen = encryptionType == "none"

        // فحص وجود HTTP proxy على مستوى JVM
        val proxyHost = System.getProperty("http.proxyHost")
        val hasProxy  = !proxyHost.isNullOrBlank()

        return mapOf(
            "ssid"             to ssid,
            "bssid"            to bssid,
            "signal"           to signal,
            "frequency"        to frequency,
            "encryption_type"  to encryptionType,
            "is_open"          to isOpen,
            "gateway"          to gateway,
            "subnet_mask"      to subnetMask,
            "has_system_proxy" to hasProxy
        )
    }

    private fun emptyWifiMap(): Map<String, Any?> = mapOf(
        "ssid"             to null,
        "bssid"            to null,
        "signal"           to null,
        "frequency"        to null,
        "encryption_type"  to "unknown",
        "is_open"          to false,
        "gateway"          to null,
        "subnet_mask"      to null,
        "has_system_proxy" to false
    )

    @SuppressLint("MissingPermission")
    private fun getEncryptionType(
        wm: WifiManager,
        currentBssid: String?,
        hasLocation: Boolean
    ): String {
        // API 31+ (Android 12): currentSecurityType متاح مباشرة على WifiInfo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return try {
                when (wm.connectionInfo.currentSecurityType) {
                    WifiInfo.SECURITY_TYPE_OPEN -> "none"
                    WifiInfo.SECURITY_TYPE_WEP  -> "wep"
                    WifiInfo.SECURITY_TYPE_PSK  -> "wpa2"
                    WifiInfo.SECURITY_TYPE_EAP  -> "eap"
                    WifiInfo.SECURITY_TYPE_SAE  -> "wpa3"
                    WifiInfo.SECURITY_TYPE_OWE  -> "owe"
                    else                        -> "unknown"
                }
            } catch (_: Exception) { "unknown" }
        }

        // API < 31: نحلّل حقل capabilities من نتائج المسح
        if (!hasLocation) return "unknown"

        return try {
            val scanResults  = wm.scanResults ?: return "unknown"
            val currentEntry = scanResults.firstOrNull { it.BSSID == currentBssid }
                ?: return "unknown"
            val caps = currentEntry.capabilities ?: return "unknown"
            when {
                caps.contains("WPA3") || caps.contains("SAE") -> "wpa3"
                caps.contains("WPA2") || caps.contains("RSN") -> "wpa2"
                caps.contains("WPA")                          -> "wpa"
                caps.contains("WEP")                          -> "wep"
                caps.contains("OWE")                          -> "owe"
                !caps.contains("WPA") && !caps.contains("WEP") -> "none"
                else                                           -> "unknown"
            }
        } catch (_: Exception) { "unknown" }
    }

    // تحويل int → عنوان IP نصي (ترتيب little-endian الخاص بـ Android)
    private fun intToIp(ip: Int): String = String.format(
        "%d.%d.%d.%d",
        ip and 0xFF,
        ip shr 8 and 0xFF,
        ip shr 16 and 0xFF,
        ip shr 24 and 0xFF
    )

    // ════════════════════════════════════
    // Apps — التطبيقات المثبّتة وأذوناتها
    // ════════════════════════════════════

    private val DANGEROUS_PERMS = setOf(
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO,
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        Manifest.permission.READ_CONTACTS,
        Manifest.permission.READ_CALL_LOG,
        Manifest.permission.READ_SMS,
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.PROCESS_OUTGOING_CALLS,
        Manifest.permission.SEND_SMS,
        Manifest.permission.RECEIVE_SMS,
        Manifest.permission.BODY_SENSORS,
        Manifest.permission.READ_EXTERNAL_STORAGE
    )

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val flagValue = PackageManager.GET_PERMISSIONS

        val packages = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledPackages(
                    PackageManager.PackageInfoFlags.of(flagValue.toLong())
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getInstalledPackages(flagValue)
            }
        } catch (_: Exception) {
            return emptyList()
        }

        return packages.mapNotNull { pkg ->
            // applicationInfo أصبح nullable منذ API الحديثة
            val appInfo = pkg.applicationInfo ?: return@mapNotNull null
            // تخطّ تطبيقات النظام
            if (appInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0) return@mapNotNull null
            // تخطّ التطبيق نفسه
            if (pkg.packageName == packageName) return@mapNotNull null

            val requestedPerms = pkg.requestedPermissions?.toList() ?: emptyList()
            val dangerous = requestedPerms.filter { DANGEROUS_PERMS.contains(it) }

            // أعِد فقط التطبيقات التي لديها أذون خطرة
            if (dangerous.isEmpty()) return@mapNotNull null

            mapOf<String, Any?>(
                "name"        to appInfo.loadLabel(pm).toString(),
                "package"     to pkg.packageName,
                "version"     to (pkg.versionName ?: ""),
                "permissions" to dangerous
            )
        }
    }

    // ════════════════════════════════════
    // Integrity — سلامة الجهاز
    // ════════════════════════════════════

    private fun checkIntegrity(): Map<String, Boolean> = mapOf(
        "is_rooted"   to isDeviceRooted(),
        "is_emulator" to isEmulator()
    )

    private fun isDeviceRooted(): Boolean {
        // فحص وجود ملفات su في المسارات الشائعة
        val suPaths = listOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        if (suPaths.any { File(it).exists() }) return true

        // test-keys تعني بناء غير رسمي (custom ROM / rooted)
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) return true

        return false
    }

    private fun isEmulator(): Boolean =
        Build.FINGERPRINT.startsWith("generic")
        || Build.FINGERPRINT.startsWith("unknown")
        || Build.MODEL.contains("google_sdk")
        || Build.MODEL.contains("Emulator")
        || Build.MODEL.contains("Android SDK built for x86")
        || Build.MANUFACTURER.contains("Genymotion")
        || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
        || Build.PRODUCT == "google_sdk"
        || Build.HARDWARE.contains("goldfish")
        || Build.HARDWARE.contains("ranchu")
}
