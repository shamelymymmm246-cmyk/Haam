import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين تفضيلات بسيطة محلياً (هل شُوهدت شرائح الترحيب؟ … إلخ).
class AppPrefs {
  AppPrefs._();

  static const _storage = FlutterSecureStorage();
  static const _kOnboardingSeen = 'onboarding_seen_v1';

  /// هل أكمل المستخدم شرائح الترحيب من قبل؟
  static Future<bool> hasSeenOnboarding() async {
    final v = await _storage.read(key: _kOnboardingSeen);
    return v == 'true';
  }

  static Future<void> markOnboardingSeen() async {
    await _storage.write(key: _kOnboardingSeen, value: 'true');
  }

  // ─── أعلام عامة (مفاتيح الميزات في لوحة التحكّم … إلخ) ───────────────
  static Future<bool> getFlag(String key, {bool fallback = false}) async {
    final v = await _storage.read(key: 'flag_$key');
    if (v == null) return fallback;
    return v == 'true';
  }

  static Future<void> setFlag(String key, bool value) async {
    await _storage.write(key: 'flag_$key', value: value.toString());
  }
}
