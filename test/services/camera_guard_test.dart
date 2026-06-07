import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/security_state.dart';

void main() {
  group('CameraGuardCollector - parsing logic', () {
    test('AppSecurityInfo models camera permissions correctly', () {
      final app = AppSecurityInfo(
        name: 'WhatsApp',
        package: 'com.whatsapp',
        version: '2.24.1',
        dangerousPerms: ['android.permission.CAMERA', 'android.permission.RECORD_AUDIO'],
        hasSpyCombo: true,
      );

      expect(app.name, 'WhatsApp');
      expect(app.dangerousPerms, contains('android.permission.CAMERA'));
      expect(app.dangerousPerms, contains('android.permission.RECORD_AUDIO'));
      expect(app.hasSpyCombo, isTrue);
    });

    test('AppSecurityInfo with only camera permission', () {
      final app = AppSecurityInfo(
        name: 'Camera App',
        package: 'com.example.camera',
        version: '1.0',
        dangerousPerms: ['android.permission.CAMERA'],
        hasSpyCombo: false,
      );

      expect(app.dangerousPerms.length, 1);
      expect(app.hasSpyCombo, isFalse);
    });

    test('AppSecurityInfo with only mic permission', () {
      final app = AppSecurityInfo(
        name: 'Recorder',
        package: 'com.example.recorder',
        version: '2.0',
        dangerousPerms: ['android.permission.RECORD_AUDIO'],
        hasSpyCombo: false,
      );

      expect(app.dangerousPerms, contains('android.permission.RECORD_AUDIO'));
      expect(app.hasSpyCombo, isFalse);
    });

    test('flaggedApps count is reflected in SecurityState', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 2,
        flaggedApps: [
          AppSecurityInfo(
            name: 'App A', package: 'com.a', version: '1',
            dangerousPerms: ['android.permission.CAMERA'], hasSpyCombo: false,
          ),
          AppSecurityInfo(
            name: 'App B', package: 'com.b', version: '1',
            dangerousPerms: ['android.permission.RECORD_AUDIO'], hasSpyCombo: false,
          ),
        ],
        lastUpdated: DateTime.now(),
      );

      expect(state.flaggedApps.length, 2);
      expect(state.appsWithDangerousPermsCount, 2);
    });

    test('CameraGuardCollector filters apps with camera/mic perms', () {
      const cameraPerm = 'android.permission.CAMERA';
      const micPerm = 'android.permission.RECORD_AUDIO';
      const locationPerm = 'android.permission.ACCESS_FINE_LOCATION';

      // Simulate _parseApp logic from CameraGuardCollector
      AppSecurityInfo parse(Map raw) {
        final perms = (raw['permissions'] as List?)?.map((p) => p.toString()).toList() ?? [];
        final hasCamera = perms.any((p) => p.contains('CAMERA'));
        final hasMic = perms.any((p) => p.contains('RECORD_AUDIO'));
        return AppSecurityInfo(
          name: raw['name'] as String? ?? raw['package'] as String? ?? 'غير معروف',
          package: raw['package'] as String? ?? '',
          version: raw['version'] as String? ?? '',
          dangerousPerms: perms.where((p) => p.contains('CAMERA') || p.contains('RECORD_AUDIO')).toList(),
          hasSpyCombo: hasCamera && hasMic,
        );
      }

      // Should be included (has CAMERA)
      final app1 = parse({'name': 'Snap', 'package': 'com.snap', 'version': '1', 'permissions': [cameraPerm]});
      expect(app1.dangerousPerms, contains(cameraPerm));

      // Should be included (has RECORD_AUDIO)
      final app2 = parse({'name': 'Mic', 'package': 'com.mic', 'version': '1', 'permissions': [micPerm]});
      expect(app2.dangerousPerms, contains(micPerm));

      // Should NOT be included (only location)
      final app3 = parse({'name': 'Maps', 'package': 'com.maps', 'version': '1', 'permissions': [locationPerm]});
      expect(app3.dangerousPerms, isEmpty);
      expect(app3.hasSpyCombo, isFalse);

      // Spy combo (CAMERA + MIC)
      final app4 = parse({'name': 'Spy', 'package': 'com.spy', 'version': '1', 'permissions': [cameraPerm, micPerm]});
      expect(app4.dangerousPerms.length, 2);
      expect(app4.hasSpyCombo, isTrue);
    });

    test('CameraGuardCollector handles null/missing permissions gracefully', () {
      AppSecurityInfo parse(Map raw) {
        final perms = (raw['permissions'] as List?)?.map((p) => p.toString()).toList() ?? [];
        final hasCamera = perms.any((p) => p.contains('CAMERA'));
        final hasMic = perms.any((p) => p.contains('RECORD_AUDIO'));
        return AppSecurityInfo(
          name: raw['name'] as String? ?? raw['package'] as String? ?? 'غير معروف',
          package: raw['package'] as String? ?? '',
          version: raw['version'] as String? ?? '',
          dangerousPerms: perms.where((p) => p.contains('CAMERA') || p.contains('RECORD_AUDIO')).toList(),
          hasSpyCombo: hasCamera && hasMic,
        );
      }

      // No permissions field
      final app1 = parse({'name': 'NoPerms', 'package': 'com.noperms', 'version': '1'});
      expect(app1.dangerousPerms, isEmpty);
      expect(app1.hasSpyCombo, isFalse);

      // Null permissions
      final app2 = parse({'name': 'NullPerms', 'package': 'com.nullperm', 'version': '1', 'permissions': null});
      expect(app2.dangerousPerms, isEmpty);

      // Missing name falls back to package
      final app3 = parse({'package': 'com.onlypkg', 'version': '1', 'permissions': []});
      expect(app3.name, 'com.onlypkg');
    });
  });

  group('RuleEngine R4 integration - spy apps detection', () {
    test('spyAppsCount counts apps with spy combo', () {
      final state = SecurityState(
        isDnsEncrypted: true,
        hasActiveVpn: false,
        activeHostsCount: 0,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 3,
        flaggedApps: [
          AppSecurityInfo(name: 'A', package: 'a', version: '1', dangerousPerms: ['CAMERA'], hasSpyCombo: false),
          AppSecurityInfo(name: 'B', package: 'b', version: '1', dangerousPerms: ['CAMERA', 'RECORD_AUDIO'], hasSpyCombo: true),
          AppSecurityInfo(name: 'C', package: 'c', version: '1', dangerousPerms: ['RECORD_AUDIO', 'CAMERA'], hasSpyCombo: true),
        ],
        lastUpdated: DateTime.now(),
      );

      expect(state.spyAppsCount, 2);
    });
  });
}
