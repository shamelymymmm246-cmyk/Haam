import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/security_state.dart';

void main() {
  group('NetworkInfo', () {
    test('encryptionLabel returns correct labels', () {
      expect(
        const NetworkInfo(isOpenNetwork: true, encryptionType: EncryptionType.none, hasSystemProxy: false).encryptionLabel,
        'مفتوحة (بدون تشفير)',
      );
      expect(
        const NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false).encryptionLabel,
        'WPA2',
      );
      expect(
        const NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa3, hasSystemProxy: false).encryptionLabel,
        'WPA3 (الأحدث)',
      );
    });

    test('signalLabel returns correct labels based on dBm', () {
      final strong = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, signal: -45);
      final good = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, signal: -60);
      final fair = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, signal: -70);
      final weak = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, signal: -85);
      final none = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false);

      expect(strong.signalLabel, 'ممتاز');
      expect(good.signalLabel, 'جيد');
      expect(fair.signalLabel, 'مقبول');
      expect(weak.signalLabel, 'ضعيف');
      expect(none.signalLabel, isNull);
    });

    test('bandLabel returns correct band for frequency', () {
      final fiveGhz = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, frequency: 5200);
      final twoGhz = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false, frequency: 2450);
      final none = NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false);

      expect(fiveGhz.bandLabel, '5 GHz');
      expect(twoGhz.bandLabel, '2.4 GHz');
      expect(none.bandLabel, isNull);
    });
  });

  group('DeviceIntegrity', () {
    test('hasCriticalTamper returns true for Frida detection', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isFridaDetected: true);
      expect(di.hasCriticalTamper, isTrue);
    });

    test('hasCriticalTamper returns true for Xposed detection', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isXposedDetected: true);
      expect(di.hasCriticalTamper, isTrue);
    });

    test('hasCriticalTamper returns true for debugger attached', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isDebuggerAttached: true);
      expect(di.hasCriticalTamper, isTrue);
    });

    test('hasCriticalTamper returns true for invalid signature', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, signatureValid: false);
      expect(di.hasCriticalTamper, isTrue);
    });

    test('hasCriticalTamper returns false when clean', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false);
      expect(di.hasCriticalTamper, isFalse);
    });

    test('hasWarningSignals returns true for rooted', () {
      final di = DeviceIntegrity(isRooted: true, isEmulator: false);
      expect(di.hasWarningSignals, isTrue);
    });

    test('hasWarningSignals returns true for emulator', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: true);
      expect(di.hasWarningSignals, isTrue);
    });

    test('activeSignals includes all triggered signals', () {
      final di = DeviceIntegrity(
        isRooted: true,
        isEmulator: true,
        isFridaDetected: true,
        isAdbEnabled: true,
        isDebuggable: true,
      );
      final signals = di.activeSignals;
      expect(signals, contains('Frida/هوكينغ'));
      expect(signals, contains('Root'));
      expect(signals, contains('محاكي'));
      expect(signals, contains('ADB مفعّل'));
      expect(signals, contains('بناء تنقيح'));
    });

    test('activeSignals empty when no signals triggered', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, hasStrongBiometric: true);
      expect(di.activeSignals, isEmpty);
    });
  });

  group('SecurityState', () {
    test('spyAppsCount counts apps with spy combo', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 3,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 2,
        flaggedApps: [
          AppSecurityInfo(name: 'Spy1', package: 'com.spy1', version: '1', dangerousPerms: ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION'], hasSpyCombo: true),
          AppSecurityInfo(name: 'Safe', package: 'com.safe', version: '1', dangerousPerms: ['CAMERA'], hasSpyCombo: false),
          AppSecurityInfo(name: 'Spy2', package: 'com.spy2', version: '1', dangerousPerms: ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION'], hasSpyCombo: true),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(state.spyAppsCount, 2);
    });

    test('empty factory creates state with defaults', () {
      final state = SecurityState.empty();
      expect(state.isDnsEncrypted, false);
      expect(state.hasActiveVpn, false);
      expect(state.activeHostsCount, 0);
      expect(state.flaggedApps, isEmpty);
    });

    test('hasSystemProxy returns networkInfo.hasSystemProxy', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );
      expect(state.hasSystemProxy, isTrue);
    });
  });

  group('AppSecurityInfo', () {
    test('correctly stores properties', () {
      final app = AppSecurityInfo(
        name: 'TestApp',
        package: 'com.test.app',
        version: '2.1',
        dangerousPerms: ['CAMERA', 'LOCATION'],
        hasSpyCombo: true,
      );
      expect(app.name, 'TestApp');
      expect(app.package, 'com.test.app');
      expect(app.dangerousPerms.length, 2);
      expect(app.hasSpyCombo, isTrue);
    });
  });
}
