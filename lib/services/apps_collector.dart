import 'package:flutter/services.dart';
import 'package:haam_counter/models/security_state.dart';

class AppsCollector {
  static const _channel = MethodChannel('com.haam.security/apps');

  // الأذونات الخطرة التي تُشير إلى تطبيقات تجمع بيانات حساسة
  static const _dangerousPerms = {
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_CALL_LOG',
    'android.permission.READ_SMS',
    'android.permission.READ_PHONE_STATE',
    'android.permission.PROCESS_OUTGOING_CALLS',
    'android.permission.SEND_SMS',
    'android.permission.RECEIVE_SMS',
    'android.permission.BODY_SENSORS',
    'android.permission.READ_EXTERNAL_STORAGE',
  };

  Future<List<AppSecurityInfo>> collect() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('getInstalledApps');
      if (raw == null) return [];
      return raw.map(_parseApp).toList();
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  AppSecurityInfo _parseApp(Map raw) {
    final perms = (raw['permissions'] as List?)
            ?.map((p) => p.toString())
            .where(_dangerousPerms.contains)
            .toList() ??
        [];

    final hasCamera = perms.contains('android.permission.CAMERA');
    final hasMic    = perms.contains('android.permission.RECORD_AUDIO');
    final hasLoc    = perms.any((p) =>
        p.contains('LOCATION') || p == 'android.permission.ACCESS_FINE_LOCATION');

    return AppSecurityInfo(
      name:         raw['name']    as String? ?? raw['package'] as String? ?? 'غير معروف',
      package:      raw['package'] as String? ?? '',
      version:      raw['version'] as String? ?? '',
      dangerousPerms: perms,
      hasSpyCombo:  hasCamera && hasMic && hasLoc,
    );
  }
}
