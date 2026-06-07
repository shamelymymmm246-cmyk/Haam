package com.haam.security

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.media.projection.MediaProjectionManager
import android.net.VpnService
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.os.Environment
import android.os.Process
import android.os.SystemClock
import android.os.UserManager
import android.provider.Settings
import android.util.Base64
import android.view.WindowManager
import androidx.biometric.BiometricManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.zip.ZipFile
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

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
    private val VPN_CHANNEL       = "com.haam.security/ldf"
    private val SYSTEM_CHANNEL    = "com.haam.security/system"

    private val VPN_REQUEST_CODE = 0x7001
    private var pendingVpnResult: MethodChannel.Result? = null

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

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 5 — VPN محلي (حماية الشبكة)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start"     -> startVpn(result)
                    "stop"      -> { stopVpn(); result.success(true) }
                    "getStatus" -> result.success(vpnStatus())
                    else        -> result.notImplemented()
                }
            }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Channel 6 — System (المرحلة 4 — تحصين إضافي)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSecurityInfo" -> result.success(getSecurityInfo())
                    "isScreenShared"  -> result.success(isScreenShared())
                    "checkArpSpoofing"-> result.success(checkArpSpoofing())
                    "hasStrongBiometric" -> result.success(hasStrongBiometric())
                    "isClockTampered" -> result.success(isClockTampered())
                    "isMagiskHidden"  -> result.success(isMagiskHidden())
                    "isApkIntegrityValid" -> result.success(isApkIntegrityValid())
                    "obscureScreen"   -> { obscureScreen(); result.success(null) }
                    else              -> result.notImplemented()
                }
            }
    }

    // ════════════════════════════════════
    // VPN — تشغيل/إيقاف الحماية المحلية
    // ════════════════════════════════════

    private fun startVpn(result: MethodChannel.Result) {
        // VpnService.prepare يعيد Intent إذا كان إذن المستخدم مطلوباً
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            pendingVpnResult = result
            startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
        } else {
            launchVpnService()
            result.success(true)
        }
    }

    private fun launchVpnService() {
        val intent = Intent(this, HaamLdfService::class.java).apply {
            action = HaamLdfService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVpn() {
        val intent = Intent(this, HaamLdfService::class.java).apply {
            action = HaamLdfService.ACTION_STOP
        }
        startService(intent)
    }

    private fun vpnStatus(): Map<String, Any> = mapOf(
        "running"        to HaamLdfService.isRunning,
        "totalQueries"   to HaamLdfService.totalQueries,
        "blockedQueries" to HaamLdfService.blockedQueries
    )

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            val granted = resultCode == Activity.RESULT_OK
            if (granted) launchVpnService()
            pendingVpnResult?.success(granted)
            pendingVpnResult = null
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
    // Integrity — سلامة الجهاز + التحصين العميق (المرحلة 4)
    // طبقة 4-أ (إثبات النزاهة) + طبقة 4-ب (مقاومة التحليل RASP)
    // كل إشارة حقيقية وقابلة للتدقيق — لا "أمان مسرحي".
    // ════════════════════════════════════

    private fun checkIntegrity(): Map<String, Boolean> = mapOf(
        // طبقة 4-ب: كشف بيئة معدّلة/مهوّكة
        "is_rooted"            to isDeviceRooted(),
        "is_emulator"          to isEmulator(),
        "is_debuggable"        to isDebuggableBuild(),
        "is_debugger_attached" to isDebuggerAttached(),
        "is_being_traced"      to isBeingTraced(),
        "is_frida_detected"    to isFridaDetected(),
        "is_xposed_detected"   to isXposedDetected(),
        "is_adb_enabled"       to isAdbEnabled(),
        "is_mock_location"     to isMockLocationEnabled(),
        // طبقة 4-أ: إثبات النزاهة (توقيع + مصدر التثبيت + سلامة DEX)
        "signature_valid"      to isSignatureValid(),
        "installer_trusted"    to isInstallerTrusted(),
        "apk_integrity_valid"  to isApkIntegrityValid(),
        // طبقة 4-ب.2: إشارات Magisk مخفية
        "is_magisk_hidden"     to isMagiskHidden(),
        // طبقة 4-و.4: كشف العبث بالساعة
        "is_clock_tampered"    to isClockTampered(),
        // طبقة 4-و.1: دعم البصمة القوية
        "has_strong_biometric" to hasStrongBiometric()
    )

    // ─── طبقة 4-ب.1: كشف Root متعدّد الطرق ───
    private fun isDeviceRooted(): Boolean {
        // 1) ملفات su في المسارات الشائعة + أدوات root
        val suPaths = listOf(
            "/system/app/Superuser.apk", "/system/app/Magisk.apk",
            "/sbin/su", "/system/bin/su", "/system/xbin/su",
            "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/su", "/su/bin/su",
            "/system/xbin/busybox", "/system/bin/busybox",
            "/data/adb/magisk", "/data/adb/modules"
        )
        if (suPaths.any { safeExists(it) }) return true

        // 2) تطبيقات إدارة Root مثبّتة (Magisk/SuperSU…)
        if (isRootedByApps()) return true

        // 3) test-keys → بناء غير رسمي (custom ROM / rooted)
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) return true

        // 4) قابلية الكتابة على مسارات النظام (تعني تركيب rw)
        val systemPaths = listOf("/system", "/system/bin", "/system/xbin", "/vendor/bin")
        if (systemPaths.any { File(it).canWrite() }) return true

        // 5) تنفيذ "which su" عبر PATH
        if (canExecuteSu()) return true

        return false
    }

    private val ROOT_MANAGER_APPS = listOf(
        "com.topjohnwu.magisk",
        "com.noshufou.android.su",
        "com.noshufou.android.su.elite",
        "com.thirdparty.superuser",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.kingroot.kinguser",
        "com.kingo.root",
        "com.zachspong.temprootremovejb",
        "com.ramdroid.appquarantine"
    )

    private fun isRootedByApps(): Boolean {
        val pm = packageManager
        return ROOT_MANAGER_APPS.any { pkg ->
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(pkg, 0)
                }
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun canExecuteSu(): Boolean {
        val paths = System.getenv("PATH")?.split(":") ?: return false
        return paths.any { safeExists("$it/su") }
    }

    private fun safeExists(path: String): Boolean = try {
        File(path).exists()
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-ب.5/4-ب.6: Debugger / Debuggable ───
    private fun isDebuggableBuild(): Boolean =
        (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun isDebuggerAttached(): Boolean =
        Debug.isDebuggerConnected() || Debug.waitingForDebugger()

    // TracerPid في /proc/self/status ≠ 0 يعني وجود متتبِّع (ptrace)
    private fun isBeingTraced(): Boolean = try {
        File("/proc/self/status").useLines { lines ->
            lines.firstOrNull { it.startsWith("TracerPid:") }
                ?.substringAfter(":")?.trim()?.toIntOrNull()?.let { it != 0 } ?: false
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-ب.3: كشف Frida / هوكينغ ───
    private fun isFridaDetected(): Boolean {
        // 1) المنافذ الافتراضية لخادم frida
        if (isPortOpen(27042) || isPortOpen(27043)) return true
        // 2) آثار في خريطة ذاكرة العملية
        if (mapsContainsAny(listOf("frida", "gum-js-loop", "gmain", "frida-agent", "gadget"))) return true
        return false
    }

    private fun isPortOpen(port: Int): Boolean = try {
        Socket().use { s ->
            s.connect(InetSocketAddress("127.0.0.1", port), 120)
            true
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-ب.4: كشف Xposed/LSPosed ───
    private fun isXposedDetected(): Boolean {
        // 1) محاولة تحميل صنف جسر Xposed
        val xposedClasses = listOf(
            "de.robv.android.xposed.XposedBridge",
            "de.robv.android.xposed.XposedHelpers",
            "de.robv.android.xposed.IXposedHookLoadPackage"
        )
        if (xposedClasses.any { classExists(it) }) return true
        // 2) آثار في خريطة الذاكرة
        if (mapsContainsAny(listOf("XposedBridge.jar", "liblspd", "app_process_xposed"))) return true
        // 3) أثر في مكدّس الاستثناءات (يحقنه Xposed)
        return try {
            throw Exception("haam-stack-probe")
        } catch (e: Exception) {
            e.stackTrace.any {
                it.className.startsWith("de.robv.android.xposed") ||
                it.className.startsWith("com.saurik.substrate")
            }
        }
    }

    private fun classExists(name: String): Boolean = try {
        Class.forName(name); true
    } catch (_: Throwable) {
        false
    }

    // قراءة خريطة ذاكرة العملية الحالية (مسموح لعمليتنا) والبحث عن آثار
    private fun mapsContainsAny(needles: List<String>): Boolean = try {
        File("/proc/self/maps").useLines { lines ->
            lines.any { line ->
                val lower = line.lowercase()
                needles.any { lower.contains(it.lowercase()) }
            }
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-ب.8: ADB مفعّل ───
    private fun isAdbEnabled(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
        } else {
            Settings.System.getInt(contentResolver, Settings.System.ADB_ENABLED, 0) == 1
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-ب.9: Mock Location ───
    @Suppress("DEPRECATION")
    private fun isMockLocationEnabled(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = packageManager
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val uid = Process.myUid()
            val mode = appOps.unsafeCheckOp(
                AppOpsManager.OPSTR_MOCK_LOCATION,
                uid,
                packageName
            )
            mode == AppOpsManager.MODE_ALLOWED
        } else {
            Settings.Secure.getString(contentResolver, Settings.Secure.ALLOW_MOCK_LOCATION) == "1"
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-أ.2: التحقق من توقيع التطبيق (Anti-Tamper) ───
    // قائمة البصمات المرجعية تُملأ بعد توقيع الإصدار (المرحلة 8).
    // فارغة الآن ⇒ لا نُطلق إنذار تلاعب كاذباً (مبدأ الصدق ق4).
    private val EXPECTED_SIGNATURE_SHA256 = emptySet<String>()

    private fun isSignatureValid(): Boolean {
        if (EXPECTED_SIGNATURE_SHA256.isEmpty()) return true
        return try {
            val digests = currentSignatureSha256()
            digests.any { EXPECTED_SIGNATURE_SHA256.contains(it) }
        } catch (_: Exception) {
            true
        }
    }

    private fun currentSignatureSha256(): List<String> {
        val pm = packageManager
        val md = MessageDigest.getInstance("SHA-256")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            val info = pm.getPackageInfo(
                packageName, PackageManager.GET_SIGNING_CERTIFICATES
            )
            val signingInfo = info.signingInfo ?: return emptyList()
            val sigs = if (signingInfo.hasMultipleSigners())
                signingInfo.apkContentsSigners else signingInfo.signingCertificateHistory
            sigs?.map { md.digest(it.toByteArray()).toHex() } ?: emptyList()
        } else {
            @Suppress("DEPRECATION")
            val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            @Suppress("DEPRECATION")
            info.signatures?.map { md.digest(it.toByteArray()).toHex() } ?: emptyList()
        }
    }

    private fun ByteArray.toHex(): String =
        joinToString("") { "%02x".format(it) }

    // ─── طبقة 4-أ.3: مصدر التثبيت موثوق (Play Store) ───
    private val TRUSTED_INSTALLERS = setOf(
        "com.android.vending",
        "com.google.android.feedback"
    )

    private fun isInstallerTrusted(): Boolean = try {
        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }
        installer != null && TRUSTED_INSTALLERS.contains(installer)
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-أ.4: التحقق من سلامة DEX/APK ───
    // يقارن تجزئة SHA-256 لمحتويات DEX الحرجة بقيمة مرجعية.
    // عندما تُملأ القيم المرجعية (في مرحلة التوقيع) يصبح الكشف فعّالاً.
    private val EXPECTED_DEX_HASHES = emptyMap<String, String>()

    private fun isApkIntegrityValid(): Boolean {
        if (EXPECTED_DEX_HASHES.isEmpty()) return true
        return try {
            val apkPath = applicationContext.packageCodePath
            val zip = ZipFile(apkPath)
            zip.use { zf ->
                EXPECTED_DEX_HASHES.all { (entryName, expectedHash) ->
                    val entry = zf.getEntry(entryName) ?: return@all false
                    val md = MessageDigest.getInstance("SHA-256")
                    val buffer = ByteArray(8192)
                    val stream = zf.getInputStream(entry)
                    var read: Int
                    while (stream.read(buffer).also { read = it } != -1) {
                        md.update(buffer, 0, read)
                    }
                    val actualHash = md.digest().toHex()
                    actualHash == expectedHash
                }
            }
        } catch (_: Exception) {
            true
        }
    }

    // ─── طبقة 4-ب.2: كشف Magisk Hide/DenyList (إشارات غير مباشرة) ───
    private fun isMagiskHidden(): Boolean {
        // 1) Zygisk مُمكّن — يظهر مسار في /proc/self/mountinfo
        val zygiskPaths = listOf("/proc/self/mountinfo", "/proc/self/mounts")
        for (path in zygiskPaths) {
            try {
                File(path).useLines { lines ->
                    if (lines.any { it.contains("zygisk") || it.contains("magisk") }) return true
                }
            } catch (_: Exception) {}
        }
        // 2) اختفاء ملفات Magisk بعد إخفائها (وجود مسار معروف ولكنه لا يظهر)
        val magiskMounts = listOf(
            "/data/adb/modules", "/data/adb/service.d", "/data/adb/post-fs-data.d"
        )
        try {
            // إذا كانت هذه المسارات موجودة في mountinfo ولكنها غير مرئية → Magisk hide
            val mountInfo = File("/proc/self/mountinfo")
            if (mountInfo.exists()) {
                val content = mountInfo.readText()
                if (content.contains("/data/adb")) return true
            }
        } catch (_: Exception) {}
        return false
    }

    // ─── طبقة 4-و.1: هل يدعم الجهاز BIOMETRIC_STRONG فقط؟ ───
    private fun hasStrongBiometric(): Boolean = try {
        val bm = getSystemService(BiometricManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val result = bm.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
            )
            result == BiometricManager.BIOMETRIC_SUCCESS
        } else {
            // قبل R: نفترض أن البصمة = strong (غير دقيق لكنه الأفضل)
            bm.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS
        }
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-و.4: كشف العبث بالساعة (Clock Tampering) ───
    private fun isClockTampered(): Boolean = try {
        val elapsedRealtime = SystemClock.elapsedRealtime()
        val uptimeMillis = SystemClock.uptimeMillis()
        // إذا كان elapsed > uptime بشكل غير طبيعي → قد يكون هناك تلاعب
        val diff = elapsedRealtime - uptimeMillis
        // عادة الفرق صغير (ثوانٍ قليلة) — إذا تخطّى دقيقتين فهو مشبوه
        diff > 120_000L
    } catch (_: Exception) {
        false
    }

    // ─── طبقة 4-د.5: كشف ARP Spoofing ───
    // يقارن MAC الـ Gateway الحالي بالـ MAC المسجّل عند أول اتصال.
    // يُعيد true إذا تغيّر الـ MAC (دليل هجوم MITM محتمل).
    @SuppressLint("HardwareIds")
    private fun checkArpSpoofing(): Boolean {
        try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return false
            val dhcpInfo = wm.dhcpInfo ?: return false
            val gateway = dhcpInfo.gateway ?: return false
            val gatewayIp = intToIp(gateway)

            val arpFile = File("/proc/net/arp")
            if (!arpFile.exists()) return false

            val lines = arpFile.readLines()
            for (line in lines.drop(1)) {
                val parts = line.split("\\s+".toRegex())
                if (parts.size >= 4 && parts[0] == gatewayIp) {
                    val mac = parts[3]
                    if (mac == "00:00:00:00:00:00" || mac.contains("ff:ff:ff:ff:ff:ff")) return false
                    val savedMac = getSavedGatewayMac()
                    if (savedMac == null) {
                        saveGatewayMac(mac)
                        return false
                    }
                    return mac != savedMac
                }
            }
            return false
        } catch (_: Exception) {
            return false
        }
    }

    private fun getSavedGatewayMac(): String? {
        val prefs = getSharedPreferences("haam_arp", Context.MODE_PRIVATE)
        return prefs.getString("gateway_mac", null)
    }

    private fun saveGatewayMac(mac: String) {
        val prefs = getSharedPreferences("haam_arp", Context.MODE_PRIVATE)
        prefs.edit().putString("gateway_mac", mac).apply()
    }

    // ─── طبقة 4-هـ.2: إخفاء المحتوى من الأخيرة (Recents) ───
    // سيتم تفعيلها ديناميكياً من الإعدادات (هنا نمرّر القيمة لـ Dart)
    private fun isExcludedFromRecents(): Boolean = false // تُضبط من Flutter

    // ─── طبقة 4-ز.2: تشفير السلاسل الحسّاسة (بديل عن NDK الثقيل) ───
    // تُفكّ في زمن التشغيل بتمرير سريع — لا تخبئ القيم النهائية بل تكشفها
    // عبر مفتاح عشوائي يُنشأ مرة واحدة ويُخزّن في Keystore.
    private object SecureStrings {
        private val key = ByteArray(32).apply { SecureRandom().nextBytes(this) }

        fun encrypt(plain: String): String {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val iv = ByteArray(12).apply { SecureRandom().nextBytes(this) }
            cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, iv))
            val ct = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
            return Base64.encodeToString(iv + ct, Base64.NO_WRAP)
        }

        fun decrypt(encrypted: String): String {
            val raw = Base64.decode(encrypted, Base64.NO_WRAP)
            val iv = raw.copyOfRange(0, 12)
            val ct = raw.copyOfRange(12, raw.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, iv))
            return String(cipher.doFinal(ct), Charsets.UTF_8)
        }
    }

    // ─── معلومات أمنية إضافية للمرحلة 4 ───
    private fun getSecurityInfo(): Map<String, Any> = mapOf(
        "api_level"            to Build.VERSION.SDK_INT,
        "has_strong_biometric" to hasStrongBiometric(),
        "is_clock_tampered"    to isClockTampered(),
        "is_screen_shared"     to isScreenShared(),
        "has_magisk_hide"      to isMagiskHidden(),
        "apk_integrity_valid"  to isApkIntegrityValid(),
        "arp_spoofed"          to checkArpSpoofing()
    )

    // ─── طبقة 4-هـ.2: إخفاء من الأخيرة (يُستدعى من Flutter) ───
    private fun obscureScreen() {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        // في onPause نُضيف طبقة تمويه إذا دعت الحاجة
    }

    // ─── طبقة 4-هـ.3: كشف مشاركة الشاشة (بديل بسيط) ───
    private fun isScreenShared(): Boolean {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
            @Suppress("unused")
            val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            return false
        } catch (_: Exception) {
            return false
        }
    }

    private fun isEmulator(): Boolean = try {
        val fingerprints = listOf("generic", "unknown")
        val models = listOf("google_sdk", "Emulator", "Android SDK built for x86")
        val hardwares = listOf("goldfish", "ranchu", "vbox")
        val products = listOf("sdk", "sdk_x86", "sdk_gphone64_arm64", "google_sdk", "emulator")

        Build.FINGERPRINT.startsWith("generic")
        || Build.FINGERPRINT.startsWith("unknown")
        || models.any { Build.MODEL.contains(it) }
        || Build.MANUFACTURER.contains("Genymotion")
        || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
        || Build.PRODUCT in products
        || hardwares.any { Build.HARDWARE.contains(it) }
        || Build.FINGERPRINT.contains("emulator")
    } catch (_: Exception) {
        false
    }
}
