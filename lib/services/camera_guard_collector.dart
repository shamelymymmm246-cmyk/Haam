import 'package:flutter/services.dart';
import 'package:haam_counter/models/security_state.dart';

/// جامع تطبيقات الكاميرا والمايك — لدرع حماية الكاميرا (المرحلة 2.1).
///
/// الواقع التقني (بدون root): لا يمكن "حجب" الوصول إلى الكاميرا، لكن يمكن:
/// - سرد التطبيقات التي تملك أذونات CAMERA و/أو RECORD_AUDIO
/// - عرضها للمستخدم مع إمكانية فتح إعدادات الأذونات لكل تطبيق
///
/// النص الصادق: "تنبّهك للتطبيقات التي قد تصل لكاميرتك/مايكك" لا "تمنعها".
class CameraGuardCollector {
  static const _channel = MethodChannel('com.haam.security/apps');

  /// يُعيد فقط التطبيقات التي لديها إذن CAMERA أو RECORD_AUDIO.
  Future<List<AppSecurityInfo>> collect() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('getInstalledApps');
      if (raw == null) return [];
      return raw
          .map(_parseApp)
          .where((a) =>
              a.dangerousPerms
                  .contains('android.permission.CAMERA') ||
              a.dangerousPerms
                  .contains('android.permission.RECORD_AUDIO'))
          .toList();
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  AppSecurityInfo _parseApp(Map raw) {
    final perms = (raw['permissions'] as List?)
            ?.map((p) => p.toString())
            .toList() ??
        [];
    final hasCamera =
        perms.any((p) => p.contains('CAMERA'));
    final hasMic =
        perms.any((p) => p.contains('RECORD_AUDIO'));

    return AppSecurityInfo(
      name: raw['name'] as String? ??
          raw['package'] as String? ??
          'غير معروف',
      package: raw['package'] as String? ?? '',
      version: raw['version'] as String? ?? '',
      dangerousPerms: perms
          .where((p) =>
              p.contains('CAMERA') || p.contains('RECORD_AUDIO'))
          .toList(),
      hasSpyCombo: hasCamera && hasMic,
    );
  }
}
