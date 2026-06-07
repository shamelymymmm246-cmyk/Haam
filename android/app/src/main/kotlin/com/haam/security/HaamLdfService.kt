package com.haam.security

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer

/**
 * فلتر DNS محلي (LDF — Local DNS Filter) يعمل بالكامل على الجهاز — بلا خادم خارجي.
 *
 * ملاحظة: يستخدم واجهة VpnService الخاصة بأندرويد محلياً (هي الوسيلة الوحيدة
 * لاعتراض حركة الشبكة دون root)، لكنه ليس VPN بالمعنى المتعارف: لا يخفي عنوان IP
 * ولا يمرّر بياناتك عبر أي خادم خارجي.
 *
 * الفكرة: ننشئ واجهة TUN ونوجّه استعلامات DNS فقط عبرها (خادم DNS وهمي).
 * لكل استعلام:
 *   • نستخرج اسم النطاق.
 *   • إن كان ضمن قائمة الحجب المحلية (إعلانات/تتبّع/نطاقات ضارة) → نردّ بحجبه فوراً.
 *   • وإلا نمرّره إلى محلّل DNS حقيقي (عبر مقبس محمي خارج النفق) ونعيد الرد.
 *
 * بقية حركة الإنترنت لا تمرّ عبر النفق (نوجّه عنوان DNS الوهمي فقط)،
 * لذا لا يتأثر اتصالك العادي ولا تُرسَل بياناتك لأي طرف.
 */
class HaamLdfService : VpnService() {

    companion object {
        const val ACTION_START = "com.haam.security.LDF_START"
        const val ACTION_STOP = "com.haam.security.LDF_STOP"

        private const val VPN_ADDRESS = "10.111.222.2"
        private const val VPN_DNS = "10.111.222.1"
        private const val UPSTREAM_DNS = "1.1.1.1"
        private const val NOTIF_CHANNEL = "haam_ldf"
        private const val NOTIF_ID = 8801

        // حالة مشتركة تقرأها طبقة Flutter عبر MethodChannel
        @Volatile var isRunning = false
            private set
        @Volatile var totalQueries = 0L
            private set
        @Volatile var blockedQueries = 0L
            private set

        // لاحقات نطاقات تُحجب (مطابقة لاحقة: example.com يحجب a.example.com أيضاً)
        // المرحلة 4 — طبقة 4-د.4: قائمة موسّعة (مصدرها فئات StevenBlack/hosts + EasyList).
        val blockList: Set<String> = setOf(
            // ── إعلانات ──
            "doubleclick.net", "googleadservices.com", "googlesyndication.com",
            "adservice.google.com", "ads.youtube.com", "pagead2.googlesyndication.com",
            "adcolony.com", "applovin.com", "unityads.unity3d.com", "adnxs.com",
            "rubiconproject.com", "pubmatic.com", "criteo.com", "taboola.com",
            "outbrain.com", "moatads.com", "amazon-adsystem.com",
            "advertising.com", "adzerk.net", "adform.net", "adsrvr.org",
            "adsafeprotected.com", "casalemedia.com", "openx.net", "smartadserver.com",
            "spotxchange.com", "teads.tv", "yieldmo.com", "sharethrough.com",
            "3lift.com", "bidswitch.net", "gumgum.com", "indexww.com",
            "media.net", "mgid.com", "revcontent.com", "zedo.com",
            "adtech.de", "advertising.amazon.com", "ad.doubleclick.net",
            "googletagservices.com", "googletagmanager.com", "2mdn.net",
            "adservice.google.ae", "adserver.adtechus.com", "adcash.com",
            // ── متتبّعات وتحليلات ──
            "google-analytics.com", "analytics.google.com", "app-measurement.com",
            "firebase-settings.crashlytics.com", "graph.facebook.com",
            "facebook.net", "connect.facebook.net", "ads.facebook.com",
            "branch.io", "appsflyer.com", "adjust.com", "app.adjust.com",
            "pixel.adjust.com", "kochava.com",
            "mixpanel.com", "segment.io", "segment.com", "amplitude.com",
            "flurry.com", "data.flurry.com",
            "scorecardresearch.com", "hotjar.com", "fullstory.com",
            "sentry.io", "datadoghq.com", "newrelic.com", "nr-data.net",
            "mouseflow.com", "luckyorange.com", "clarity.ms",
            "quantserve.com", "quantcount.com", "chartbeat.com", "cxense.com",
            "demdex.net", "omtrdc.net", "everesttech.net", "krxd.net",
            "bluekai.com", "rlcdn.com", "agkn.com", "tapad.com",
            "crwdcntrl.net", "exelator.com", "mathtag.com", "bidr.io",
            "mc.yandex.ru", "metrika.yandex.ru",
            "umeng.com", "talkingdata.com", "inmobi.com",
            // ── CDN إعلانية ──
            "cdn.adsafeprotected.com", "ad.atdmt.com", "adserver.yahoo.com",
            "geo.yahoo.com", "analytics.yahoo.com", "log.outbrain.com",
            // ── برمجيات ضارة/تصيّد/تجسّس معروفة (فئات شائعة) ──
            "malware.test", "phishing.test",
            "coinhive.com", "coin-hive.com", "cryptoloot.pro", "jsecoin.com",
            "miner.start.gg", "webminepool.com"
        )

        fun resetStats() {
            totalQueries = 0
            blockedQueries = 0
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var worker: Thread? = null
    @Volatile private var running = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopVpn()
                return START_NOT_STICKY
            }
            else -> startVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (running) return
        startForegroundNotification()

        val builder = Builder()
            .setSession("حام — حماية محلية")
            .addAddress(VPN_ADDRESS, 32)
            .addDnsServer(VPN_DNS)
            // نوجّه عنوان DNS الوهمي فقط عبر النفق — بقية الحركة تمرّ طبيعياً
            .addRoute(VPN_DNS, 32)
            .setMtu(1500)

        // لا نطبّق الفلتر على التطبيق نفسه
        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: Exception) {
        }

        vpnInterface = try {
            builder.establish()
        } catch (_: Exception) {
            null
        }

        if (vpnInterface == null) {
            stopVpn()
            return
        }

        resetStats()
        running = true
        isRunning = true

        worker = Thread({ runLoop() }, "haam-vpn-dns").apply { start() }
    }

    private fun runLoop() {
        val pfd = vpnInterface ?: return
        val input = FileInputStream(pfd.fileDescriptor)
        val output = FileOutputStream(pfd.fileDescriptor)
        val packet = ByteArray(32767)

        while (running) {
            val length = try {
                input.read(packet)
            } catch (_: Exception) {
                break
            }
            if (length <= 0) continue

            try {
                handlePacket(packet, length, output)
            } catch (_: Exception) {
                // نتجاهل الحزم التالفة ونكمل
            }
        }

        try {
            input.close()
            output.close()
        } catch (_: Exception) {
        }
    }

    /** نعالج حزمة IPv4/UDP المتجهة إلى خادم DNS الوهمي. */
    private fun handlePacket(packet: ByteArray, length: Int, output: FileOutputStream) {
        // IPv4 فقط
        val version = (packet[0].toInt() shr 4) and 0xF
        if (version != 4) return

        val ihl = (packet[0].toInt() and 0xF) * 4
        val protocol = packet[9].toInt() and 0xFF
        if (protocol != 17) return // UDP فقط

        val udpStart = ihl
        val dstPort = ((packet[udpStart + 2].toInt() and 0xFF) shl 8) or
            (packet[udpStart + 3].toInt() and 0xFF)
        if (dstPort != 53) return

        val udpHeaderLen = 8
        val dnsStart = udpStart + udpHeaderLen
        val dnsLength = length - dnsStart
        if (dnsLength <= 12) return

        val dnsQuery = packet.copyOfRange(dnsStart, length)
        val domain = parseDomain(dnsQuery) ?: return

        totalQueries++

        if (isBlocked(domain)) {
            blockedQueries++
            val response = buildBlockedResponse(dnsQuery)
            writeResponse(packet, ihl, udpStart, response, output)
        } else {
            val response = resolveUpstream(dnsQuery) ?: return
            writeResponse(packet, ihl, udpStart, response, output)
        }
    }

    /** يستخرج اسم النطاق من قسم السؤال في حزمة DNS. */
    private fun parseDomain(dns: ByteArray): String? {
        var pos = 12 // بعد الترويسة
        val sb = StringBuilder()
        while (pos < dns.size) {
            val len = dns[pos].toInt() and 0xFF
            if (len == 0) break
            if (len and 0xC0 != 0) return null // ضغط غير متوقع في السؤال
            pos++
            if (pos + len > dns.size) return null
            if (sb.isNotEmpty()) sb.append('.')
            for (i in 0 until len) {
                sb.append((dns[pos + i].toInt() and 0xFF).toChar())
            }
            pos += len
        }
        return if (sb.isEmpty()) null else sb.toString().lowercase()
    }

    private fun isBlocked(domain: String): Boolean {
        if (blockList.contains(domain)) return true
        return blockList.any { domain.endsWith(".$it") }
    }

    /** يبني رد DNS يحجب النطاق (A → 0.0.0.0) أو NODATA لغير A. */
    private fun buildBlockedResponse(query: ByteArray): ByteArray {
        // نوع السؤال (qtype) آخر السؤال
        var pos = 12
        while (pos < query.size && (query[pos].toInt() and 0xFF) != 0) {
            pos += (query[pos].toInt() and 0xFF) + 1
        }
        val qtypePos = pos + 1
        val qtype = if (qtypePos + 1 < query.size)
            ((query[qtypePos].toInt() and 0xFF) shl 8) or (query[qtypePos + 1].toInt() and 0xFF)
        else 0
        val questionEnd = qtypePos + 4 // qtype(2) + qclass(2)

        val buf = ByteBuffer.allocate(query.size + 16)
        // الترويسة: ننسخ معرّف المعاملة
        buf.put(query[0]); buf.put(query[1])
        // أعلام: QR=1, RD copy, RA=1, RCODE=0
        buf.put(0x81.toByte()); buf.put(0x80.toByte())
        buf.putShort(1) // QDCOUNT
        val isA = qtype == 1
        buf.putShort(if (isA) 1 else 0) // ANCOUNT
        buf.putShort(0) // NSCOUNT
        buf.putShort(0) // ARCOUNT
        // قسم السؤال كما هو
        buf.put(query, 12, questionEnd - 12)
        if (isA) {
            buf.putShort(0xC00C.toShort()) // مؤشر إلى الاسم
            buf.putShort(1)   // TYPE A
            buf.putShort(1)   // CLASS IN
            buf.putInt(60)    // TTL
            buf.putShort(4)   // RDLENGTH
            buf.put(byteArrayOf(0, 0, 0, 0)) // 0.0.0.0
        }
        val out = ByteArray(buf.position())
        buf.rewind(); buf.get(out)
        return out
    }

    /** يمرّر الاستعلام إلى محلّل حقيقي عبر مقبس محمي خارج النفق. */
    private fun resolveUpstream(query: ByteArray): ByteArray? {
        var socket: DatagramSocket? = null
        return try {
            socket = DatagramSocket()
            protect(socket) // مهم: يمنع الاستعلام من العودة عبر النفق
            socket.soTimeout = 5000
            val addr = InetAddress.getByName(UPSTREAM_DNS)
            socket.send(DatagramPacket(query, query.size, addr, 53))
            val buf = ByteArray(2048)
            val resp = DatagramPacket(buf, buf.size)
            socket.receive(resp)
            buf.copyOfRange(0, resp.length)
        } catch (_: Exception) {
            null
        } finally {
            socket?.close()
        }
    }

    /** يلفّ رد DNS في حزمة IP/UDP ويكتبها في واجهة TUN. */
    private fun writeResponse(
        request: ByteArray,
        ihl: Int,
        udpStart: Int,
        dnsResponse: ByteArray,
        output: FileOutputStream
    ) {
        val totalLen = ihl + 8 + dnsResponse.size
        val out = ByteArray(totalLen)

        // ننسخ ترويسة IP ونعكس العناوين
        System.arraycopy(request, 0, out, 0, ihl)
        // طول الحزمة الكلّي
        out[2] = ((totalLen shr 8) and 0xFF).toByte()
        out[3] = (totalLen and 0xFF).toByte()
        // عكس عنوان المصدر/الوجهة (4 بايت لكلٍّ منهما)
        for (i in 0 until 4) {
            val src = request[12 + i]
            out[12 + i] = request[16 + i]
            out[16 + i] = src
        }
        // إعادة حساب checksum لترويسة IP
        out[10] = 0; out[11] = 0
        val ipChecksum = checksum(out, 0, ihl)
        out[10] = ((ipChecksum shr 8) and 0xFF).toByte()
        out[11] = (ipChecksum and 0xFF).toByte()

        // ترويسة UDP: عكس المنافذ
        val udp = udpStart
        // منفذ المصدر الجديد = منفذ الوجهة القديم (53)
        out[udp] = request[udp + 2]; out[udp + 1] = request[udp + 3]
        // منفذ الوجهة الجديد = منفذ المصدر القديم
        out[udp + 2] = request[udp]; out[udp + 3] = request[udp + 1]
        val udpLen = 8 + dnsResponse.size
        out[udp + 4] = ((udpLen shr 8) and 0xFF).toByte()
        out[udp + 5] = (udpLen and 0xFF).toByte()
        // البيانات
        System.arraycopy(dnsResponse, 0, out, udp + 8, dnsResponse.size)
        // checksum لـ UDP (مع الترويسة الزائفة)
        out[udp + 6] = 0; out[udp + 7] = 0
        val udpChecksum = udpChecksum(out, ihl, udpLen)
        out[udp + 6] = ((udpChecksum shr 8) and 0xFF).toByte()
        out[udp + 7] = (udpChecksum and 0xFF).toByte()

        output.write(out, 0, totalLen)
        output.flush()
    }

    private fun checksum(data: ByteArray, offset: Int, length: Int): Int {
        var sum = 0L
        var i = offset
        val end = offset + length
        while (i + 1 < end) {
            sum += ((data[i].toInt() and 0xFF) shl 8) or (data[i + 1].toInt() and 0xFF)
            i += 2
        }
        if (i < end) sum += (data[i].toInt() and 0xFF) shl 8
        while (sum shr 16 != 0L) sum = (sum and 0xFFFF) + (sum shr 16)
        return (sum.inv() and 0xFFFF).toInt()
    }

    private fun udpChecksum(packet: ByteArray, ihl: Int, udpLen: Int): Int {
        var sum = 0L
        // الترويسة الزائفة: عنوان المصدر + الوجهة (8 بايت) + بروتوكول + طول UDP
        for (i in 12 until 20 step 2) {
            sum += ((packet[i].toInt() and 0xFF) shl 8) or (packet[i + 1].toInt() and 0xFF)
        }
        sum += 17 // بروتوكول UDP
        sum += udpLen
        // مقطع UDP نفسه
        var i = ihl
        val end = ihl + udpLen
        while (i + 1 < end) {
            sum += ((packet[i].toInt() and 0xFF) shl 8) or (packet[i + 1].toInt() and 0xFF)
            i += 2
        }
        if (i < end) sum += (packet[i].toInt() and 0xFF) shl 8
        while (sum shr 16 != 0L) sum = (sum and 0xFFFF) + (sum shr 16)
        val result = (sum.inv() and 0xFFFF).toInt()
        return if (result == 0) 0xFFFF else result
    }

    private fun startForegroundNotification() {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL,
                "حماية الشبكة",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "تعمل حماية حام المحلية" }
            nm.createNotificationChannel(channel)
        }

        val openIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notification: Notification =
            Notification.Builder(this, NOTIF_CHANNEL)
                .setContentTitle("حماية حام نشطة")
                .setContentText("يُحجب الإعلانات والمتتبّعات محلياً")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(openIntent)
                .setOngoing(true)
                .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun stopVpn() {
        running = false
        isRunning = false
        worker?.interrupt()
        worker = null
        try {
            vpnInterface?.close()
        } catch (_: Exception) {
        }
        vpnInterface = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onRevoke() {
        // عند سحب إذن الـVPN من النظام
        stopVpn()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
