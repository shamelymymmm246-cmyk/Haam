import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:haam_counter/services/auth_manager.dart';

/// خدمة المصادقة — تدعم البصمة/PIN مع دمج AuthManager للتأخير التصاعدي.
///
/// المرحلة 4 — طبقة 4-و:
/// - BIOMETRIC_STRONG فقط (رفض بصمة الوجه 2D غير الموثوقة).
/// - حد محاولات + تأخير تصاعدي (عبر AuthManager).
class AuthService {
  static final _auth = LocalAuthentication();
  static final _channel = MethodChannel('com.haam.security/system');
  static final _authManager = AuthManager();

  /// هل الجهاز مؤمّن ببصمة قوية (Class 3) أو PIN/نمط/رقم سري؟
  static Future<bool> isDeviceSecured() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (canCheck) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// هل البصمة المتوفّرة من النوع القوي (BIOMETRIC_STRONG)؟
  static Future<bool> hasStrongBiometric() async {
    try {
      return await _channel.invokeMethod<bool>('hasStrongBiometric') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// المصادقة مع دعم التأخير التصاعدي.
  /// يُعيد `AuthResult` بدلاً من bool لتمييز حالة القفل.
  static Future<AuthResult> authenticate({bool forceBiometric = false}) async {
    // تحقق من الإغلاق
    final lockedOut = await _authManager.isLockedOut();
    if (lockedOut) {
      return AuthResult.lockedOut;
    }

    try {
      if (!await isDeviceSecured()) return AuthResult.noSecurity;

      // للعمليات الحرجة (الخزنة)، نطلب بصمة قوية فقط
      if (forceBiometric) {
        final hasStrong = await hasStrongBiometric();
        if (!hasStrong) {
          return AuthResult.noStrongBiometric;
        }
      }

      final success = await _auth.authenticate(
        localizedReason:
            forceBiometric
                ? 'يُرجى التحقق ببصمتك للوصول إلى الخزنة'
                : 'يُرجى التحقق من هويتك للوصول إلى حام',
        options: AuthenticationOptions(
          biometricOnly: forceBiometric,
          stickyAuth: true,
        ),
      );

      if (success) {
        await _authManager.recordSuccessfulAttempt();
        return AuthResult.success;
      } else {
        final reachedMax = await _authManager.recordFailedAttempt();
        if (reachedMax) return AuthResult.maxAttemptsReached;
        return AuthResult.failed;
      }
    } catch (_) {
      return AuthResult.failed;
    }
  }

  /// الوصول إلى مدير المحاولات (للعرض في الإعدادات).
  static AuthManager get authManager => _authManager;
}

/// نتيجة المصادقة مع تفاصيل أكثر.
enum AuthResult {
  success,
  failed,
  lockedOut,
  noSecurity,
  noStrongBiometric,
  maxAttemptsReached,
}

extension AuthResultExt on AuthResult {
  String get label {
    switch (this) {
      case AuthResult.success:
        return 'تم التحقق';
      case AuthResult.failed:
        return 'فشل التحقق';
      case AuthResult.lockedOut:
        return 'التطبيق مقفل مؤقتاً — كرر المحاولة لاحقاً';
      case AuthResult.noSecurity:
        return 'الجهاز غير مؤمّن — يمكنك الدخول بدون بصمة';
      case AuthResult.noStrongBiometric:
        return 'البصمة المتوفّرة ليست قوية بما يكفي للخزنة';
      case AuthResult.maxAttemptsReached:
        return 'تم تجاوز الحد الأقصى للمحاولات — سيتم مسح الخزنة';
    }
  }
}

