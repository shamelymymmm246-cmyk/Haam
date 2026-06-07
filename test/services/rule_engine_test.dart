import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/services/rule_engine.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
  });

  group('RuleEngine R1 - Open Network', () {
    test('triggers R1 when network is open', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: true, encryptionType: EncryptionType.none, hasSystemProxy: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R1'), isTrue);
      expect(result.totalRisk, greaterThanOrEqualTo(35));
    });

    test('does not trigger R1 when network is secure', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: false, encryptionType: EncryptionType.wpa2, hasSystemProxy: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R1'), isFalse);
    });
  });

  group('RuleEngine R2 - DNS Encryption', () {
    test('triggers R2 when DNS is not encrypted', () {
      final state = SecurityState(
        isDnsEncrypted: false,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R2'), isTrue);
    });

    test('does not trigger R2 when DNS is encrypted', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R2'), isFalse);
    });
  });

  group('RuleEngine R3 - New Devices', () {
    test('triggers R3 when new devices detected', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 5,
        newDevicesDetected: true,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R3'), isTrue);
    });

    test('does not trigger R3 when no new devices', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 3,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R3'), isFalse);
    });
  });

  group('RuleEngine R4 - Spy Apps', () {
    test('triggers R4 when spy apps present', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 3,
        flaggedApps: [
          AppSecurityInfo(name: 'Spy', package: 'com.spy', version: '1', dangerousPerms: ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION'], hasSpyCombo: true),
        ],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R4'), isTrue);
    });

    test('does not trigger R4 when no spy apps', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R4'), isFalse);
    });
  });

  group('RuleEngine R5 - Rooted Device', () {
    test('triggers R5 when device is rooted', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: true, isEmulator: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R5'), isTrue);
    });

    test('does not trigger R5 when device is not rooted', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R5'), isFalse);
    });
  });

  group('RuleEngine R6 - Anomaly Detection', () {
    test('triggers R6 when anomaly score is high with enough samples', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
        anomalyScore: 0.85,
        anomalySampleCount: 10,
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R6'), isTrue);
    });

    test('does not trigger R6 with too few samples', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
        anomalyScore: 0.85,
        anomalySampleCount: 2,
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R6'), isFalse);
    });

    test('does not trigger R6 with low anomaly score', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
        anomalyScore: 0.30,
        anomalySampleCount: 10,
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R6'), isFalse);
    });
  });

  group('RuleEngine R7 - Critical Tamper', () {
    test('triggers R7 when Xposed detected', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isXposedDetected: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isTrue);
    });

    test('triggers R7 when debugger attached', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isDebuggerAttached: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isTrue);
    });

    test('triggers R7 when being traced', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isBeingTraced: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isTrue);
    });

    test('triggers R7 when signature invalid', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, signatureValid: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isTrue);
    });

    test('triggers R7 when APK integrity invalid', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, apkIntegrityValid: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isTrue);
    });

    test('does not trigger R7 when clean', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R7'), isFalse);
    });
  });

  group('RuleEngine R8 - Suspicious Environment', () {
    test('triggers R8 when Magisk hidden detected', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isMagiskHidden: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R8'), isTrue);
    });

    test('triggers R8 when clock tampered detected', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isClockTampered: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R8'), isTrue);
    });

    test('triggers R8 when both Magisk hidden and clock tampered', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false, isMagiskHidden: true, isClockTampered: true),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R8'), isTrue);
    });

    test('does not trigger R8 when clean', () {
      final state = SecurityState(
        deviceIntegrity: DeviceIntegrity(isRooted: false, isEmulator: false),
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.triggeredRules.any((r) => r.id == 'R8'), isFalse);
    });
  });

  group('RuleEngine Scoring', () {
    test('totalRisk is clamped to 100', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: true, encryptionType: EncryptionType.none, hasSystemProxy: false),
        isDnsEncrypted: false,
        hasActiveVpn: false,
        activeHostsCount: 5,
        newDevicesDetected: true,
        appsWithDangerousPermsCount: 3,
        flaggedApps: [
          AppSecurityInfo(name: 'Spy', package: 'com.spy', version: '1', dangerousPerms: ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION'], hasSpyCombo: true),
        ],
        deviceIntegrity: DeviceIntegrity(isRooted: true, isEmulator: false),
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.totalRisk, lessThanOrEqualTo(100));
      expect(result.totalRisk, greaterThanOrEqualTo(0));
    });

    test('RiskLevel is safe when totalRisk <= 20', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.level, RiskLevel.safe);
    });

    test('RiskLevel is warning when totalRisk is 21-50', () {
      final state = SecurityState(
        isDnsEncrypted: false,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: true,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.level, RiskLevel.warning);
    });

    test('RiskLevel is danger when totalRisk > 50', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: true, encryptionType: EncryptionType.none, hasSystemProxy: false),
        isDnsEncrypted: false,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      expect(result.level, RiskLevel.danger);
    });

    test('each rule result has correct structure', () {
      final state = SecurityState(
        networkInfo: NetworkInfo(isOpenNetwork: true, encryptionType: EncryptionType.none, hasSystemProxy: false),
        isDnsEncrypted: false,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 0,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      final result = engine.evaluate(state);
      for (final rule in result.triggeredRules) {
        expect(rule.id, isNotEmpty);
        expect(rule.reason, isNotEmpty);
        expect(rule.suggestedAction, isNotEmpty);
        expect(rule.riskWeight, greaterThan(0));
      }
    });
  });
}
