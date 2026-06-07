import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/security_state.dart';

void main() {
  group('NetworkInfo - Phase 3.6 verification', () {
    test('open network shows correct encryption label', () {
      final info = NetworkInfo(
        isOpenNetwork: true,
        encryptionType: EncryptionType.none,
        hasSystemProxy: false,
      );
      expect(info.isOpenNetwork, isTrue);
      expect(info.encryptionLabel, 'مفتوحة (بدون تشفير)');
    });

    test('WPA2 network shows correct encryption label', () {
      final info = NetworkInfo(
        isOpenNetwork: false,
        encryptionType: EncryptionType.wpa2,
        hasSystemProxy: false,
        ssid: 'HomeWiFi',
        bssid: '00:11:22:33:44:55',
        gateway: '192.168.1.1',
        signal: -55,
        frequency: 5200,
      );
      expect(info.ssid, 'HomeWiFi');
      expect(info.bssid, '00:11:22:33:44:55');
      expect(info.gateway, '192.168.1.1');
      expect(info.encryptionLabel, 'WPA2');
      expect(info.signalLabel, 'جيد');
      expect(info.bandLabel, '5 GHz');
    });

    test('weak signal on 2.4GHz', () {
      final info = NetworkInfo(
        isOpenNetwork: true,
        encryptionType: EncryptionType.none,
        hasSystemProxy: false,
        signal: -85,
        frequency: 2450,
      );
      expect(info.signalLabel, 'ضعيف');
      expect(info.bandLabel, '2.4 GHz');
    });

    test('WPA3 latest encryption', () {
      final info = NetworkInfo(
        isOpenNetwork: false,
        encryptionType: EncryptionType.wpa3,
        hasSystemProxy: false,
      );
      expect(info.encryptionLabel, 'WPA3 (الأحدث)');
    });

    test('system proxy detection', () {
      final info = NetworkInfo(
        isOpenNetwork: false,
        encryptionType: EncryptionType.wpa2,
        hasSystemProxy: true,
      );
      expect(info.hasSystemProxy, isTrue);
    });
  });
}
