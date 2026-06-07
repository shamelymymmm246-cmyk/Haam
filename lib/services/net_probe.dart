import 'dart:io';

/// قياسات شبكة حقيقية بسيطة — زمن الاستجابة (RTT) وعنوان IP المحلي.
/// كلها محلية بدون أي خادم خاص بالتطبيق.
class NetProbe {
  /// يقيس زمن الذهاب والإياب بفتح اتصال TCP إلى خادم DNS عام (1.1.1.1:53).
  /// يعيد المللي ثانية أو null عند الفشل/انقطاع الاتصال.
  Future<int?> measureLatency({
    String host = '1.1.1.1',
    int port = 53,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  /// عنوان IPv4 المحلي للجهاز على الشبكة (مثل 192.168.x.x).
  Future<String?> localIPv4() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      // فضّل واجهات الواي فاي/البيانات
      for (final i in ifaces) {
        for (final a in i.addresses) {
          if (!a.isLoopback && a.address.isNotEmpty) return a.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
