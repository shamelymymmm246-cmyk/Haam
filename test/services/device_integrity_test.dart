import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/security_state.dart';

void main() {
  group('DeviceIntegrity - Phase 3.5 verification', () {
    test('non-rooted device shows "سليم"', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false);
      expect(di.isRooted, isFalse);
      expect(di.hasWarningSignals, isFalse);
    });

    test('rooted device properly detected', () {
      final di = DeviceIntegrity(isRooted: true, isEmulator: false);
      expect(di.isRooted, isTrue);
      expect(di.hasWarningSignals, isTrue);
    });

    test('emulator properly detected', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: true);
      expect(di.isEmulator, isTrue);
      expect(di.hasWarningSignals, isTrue);
    });

    test('debuggable build detected', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isDebuggable: true);
      expect(di.isDebuggable, isTrue);
      expect(di.hasWarningSignals, isTrue);
    });

    test('ADB enabled detected', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isAdbEnabled: true);
      expect(di.isAdbEnabled, isTrue);
      expect(di.hasWarningSignals, isTrue);
    });

    test('mock location detected', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false, isMockLocation: true);
      expect(di.isMockLocation, isTrue);
      expect(di.hasWarningSignals, isTrue);
    });

    test('clean device has no warning signals', () {
      final di = DeviceIntegrity(isRooted: false, isEmulator: false);
      expect(di.hasWarningSignals, isFalse);
      expect(di.hasCriticalTamper, isFalse);
    });

    test('default values are safe', () {
      const di = DeviceIntegrity(isRooted: false, isEmulator: false);
      expect(di.signatureValid, isTrue);
      expect(di.installerTrusted, isTrue);
    });
  });
}
