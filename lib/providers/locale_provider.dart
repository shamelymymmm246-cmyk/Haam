import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _kLocaleKey = 'app_locale';

  Locale _locale = const Locale('ar', 'SA');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final stored = await _storage.read(key: _kLocaleKey);
    if (stored == 'en') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('ar', 'SA');
    }
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    await _storage.write(key: _kLocaleKey, value: code);
    _locale = Locale(code, code == 'ar' ? 'SA' : 'US');
    notifyListeners();
  }
}
