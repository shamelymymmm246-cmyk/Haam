import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  // يتحقق هل الجهاز مُعدّ بقفل (PIN / نقش / بيومتري)
  static Future<bool> isDeviceSecured() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // يطلب التحقق من الهوية — يعيد true فوراً لو لا يوجد قفل مُعدّ
  static Future<bool> authenticate() async {
    try {
      if (!await isDeviceSecured()) return true;
      return await _auth.authenticate(
        localizedReason: 'يُرجى التحقق من هويتك للوصول إلى حام',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
