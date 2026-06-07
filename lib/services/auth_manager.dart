import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مدير المصادقة مع دعم التأخير التصاعدي (exponential backoff) بعد الفشل
/// المتكرر. المرحلة 4 — طبقة 4-و (مصادقة وقفل صلب).
///
/// القواعد:
/// - بعد 3 محاولات فاشلة → تأخير 30 ثانية
/// - بعد 5 محاولات فاشلة → تأخير 5 دقائق
/// - بعد 7 محاولات فاشلة → تأخير 30 دقيقة
/// - إجمالي 10 محاولات فاشلة متتالية → قفل دائم (يُطلب مسح الخزنة)
///
/// كل محاولة ناجحة تُعيد ضبط العدّاد.
class AuthManager {
  static const _kFailCountKey = 'auth_fail_count';
  static const _kLockoutUntilKey = 'auth_lockout_until';

  final FlutterSecureStorage _storage;

  AuthManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// عدد المحاولات الفاشلة المتتالية.
  Future<int> getFailCount() async {
    final v = await _storage.read(key: _kFailCountKey);
    return v != null ? int.tryParse(v) ?? 0 : 0;
  }

  Future<void> _setFailCount(int count) async {
    await _storage.write(key: _kFailCountKey, value: count.toString());
  }

  /// هل نحن في فترة إغلاق (lockout)؟
  Future<bool> isLockedOut() async {
    final until = await _lockoutUntil();
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    // انتهت المهلة — أعِد ضبط العدّاد
    await _resetLockout();
    return false;
  }

  Future<DateTime?> _lockoutUntil() async {
    final v = await _storage.read(key: _kLockoutUntilKey);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> _setLockoutUntil(DateTime until) async {
    await _storage.write(key: _kLockoutUntilKey, value: until.toIso8601String());
  }

  Future<void> _resetLockout() async {
    await _storage.delete(key: _kLockoutUntilKey);
  }

  /// وقت انتهاء الإغلاق (للعرض).
  Future<DateTime?> getLockoutEnd() => _lockoutUntil();

  /// سجّل محاولة فاشلة وطبق التأخير التصاعدي.
  /// يُعيد true إذا وصلنا إلى الحد الأقصى (10).
  Future<bool> recordFailedAttempt() async {
    final count = await getFailCount();
    final newCount = count + 1;
    await _setFailCount(newCount);

    if (newCount >= 10) {
      // قفل دائم — لا نؤقت، المُستخدم يحتاج تدخلاً يدوياً
      return true; // reached max
    }

    // احسب المهلة حسب عدد المحاولات
    final delaySeconds = _backoffSeconds(newCount);
    if (delaySeconds > 0) {
      await _setLockoutUntil(
        DateTime.now().add(Duration(seconds: delaySeconds)),
      );
    }

    return false;
  }

  /// سجّل محاولة ناجحة (أعِد ضبط العدّاد).
  Future<void> recordSuccessfulAttempt() async {
    await _setFailCount(0);
    await _resetLockout();
  }

  /// التأخير التصاعدي (بالثواني).
  static int _backoffSeconds(int failCount) {
    switch (failCount) {
      case 1:
      case 2:
        return 0; // لا تأخير
      case 3:
      case 4:
        return 30; // 30 ثانية
      case 5:
      case 6:
        return 300; // 5 دقائق
      case 7:
      case 8:
      case 9:
        return 1800; // 30 دقيقة
      default:
        return 0;
    }
  }

  /// هل وصلنا إلى الحد الأقصى من المحاولات الفاشلة؟
  Future<bool> hasReachedMaxAttempts() async {
    final count = await getFailCount();
    return count >= 10;
  }

  /// يعيد ضبط كل شيء (للإعدادات/اختبار).
  Future<void> reset() async {
    await _setFailCount(0);
    await _resetLockout();
  }
}
