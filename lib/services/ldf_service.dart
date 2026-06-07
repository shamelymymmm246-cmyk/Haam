import 'package:flutter/services.dart';
import 'package:haam_counter/models/ldf_status.dart';

/// واجهة Dart للتحكّم بفلتر DNS المحلي (LDF — Local DNS Filter) عبر MethodChannel.
class LdfService {
  static const _channel = MethodChannel('com.haam.security/ldf');

  /// يطلب التشغيل — قد يظهر للمستخدم حوار إذن النظام (يستخدم واجهة VpnService
  /// الخاصة بأندرويد محلياً لاعتراض DNS فقط، دون أي خادم خارجي).
  /// يعيد true إذا مُنح الإذن وبدأت الخدمة.
  Future<bool> start() async {
    try {
      return await _channel.invokeMethod<bool>('start') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException {
      // نتجاهل
    }
  }

  Future<LdfStatus> getStatus() async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
      if (map == null) return LdfStatus.idle();
      return LdfStatus.fromMap(map);
    } on PlatformException {
      return LdfStatus.idle();
    }
  }
}
