import 'dart:io';

class NetworkDevicesCollector {
  // بورتات شائعة — وجود أي منها يعني أن الجهاز نشط
  static const _scanPorts = [80, 443, 22, 8080];
  // حد زمني لكل محاولة اتصال
  static const _timeoutMs = 200;
  // أقصى وقت إجمالي للمسح
  static const _totalTimeoutSec = 8;

  Future<int> scanActiveHosts(String? gateway) async {
    if (gateway == null || gateway.isEmpty) return 0;

    final parts = gateway.split('.');
    if (parts.length != 4) return 0;

    // اشتق الـ prefix من الـ gateway فعلياً (لا تفترض 192.168.1.x)
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    try {
      final futures = List.generate(
        254,
        (i) => _isHostActive('$prefix.${i + 1}'),
      );

      final results = await Future.wait(futures, eagerError: false)
          .timeout(Duration(seconds: _totalTimeoutSec));

      return results.where((active) => active).length;
    } catch (_) {
      // timeout أو خطأ شبكة — نُعيد 0 بدل تعطّل التطبيق
      return 0;
    }
  }

  Future<bool> _isHostActive(String host) async {
    for (final port in _scanPorts) {
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(milliseconds: _timeoutMs),
        );
        socket.destroy();
        return true;
      } on SocketException {
        // البورت مغلق أو الجهاز غير موجود — جرّب التالي
      } catch (_) {
        // أي خطأ آخر — تجاهل وانتقل للتالي
      }
    }
    return false;
  }
}
