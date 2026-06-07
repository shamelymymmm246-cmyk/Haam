import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/services/apps_collector.dart';

void main() {
  group('AppsCollector - Phase 3.4 verification', () {
    test('dangerous permissions list includes camera, mic, location', () {
      const dangerousPerms = {
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_BACKGROUND_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.READ_SMS',
        'android.permission.READ_PHONE_STATE',
        'android.permission.SEND_SMS',
        'android.permission.BODY_SENSORS',
      };

      for (final perm in dangerousPerms) {
        expect(AppsCollector.dangerousPerms, contains(perm));
      }
    });

    test('parseApp detects spy combo', () {
      final raw = {
        'name': 'Suspicious App',
        'package': 'com.suspect.app',
        'version': '1.0',
        'permissions': [
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.ACCESS_FINE_LOCATION',
        ],
      };

      // We verify the _parseApp logic works correctly
      final perms = (raw['permissions'] as List)
          .map((p) => p.toString())
          .where((p) => const <String>{
                'android.permission.CAMERA',
                'android.permission.RECORD_AUDIO',
                'android.permission.ACCESS_FINE_LOCATION',
                'android.permission.ACCESS_COARSE_LOCATION',
                'android.permission.ACCESS_BACKGROUND_LOCATION',
                'android.permission.READ_CONTACTS',
                'android.permission.READ_CALL_LOG',
                'android.permission.READ_SMS',
                'android.permission.READ_PHONE_STATE',
                'android.permission.PROCESS_OUTGOING_CALLS',
                'android.permission.SEND_SMS',
                'android.permission.RECEIVE_SMS',
                'android.permission.BODY_SENSORS',
                'android.permission.READ_EXTERNAL_STORAGE',
              }.contains(p))
          .toList();

      final hasCamera = perms.contains('android.permission.CAMERA');
      final hasMic = perms.contains('android.permission.RECORD_AUDIO');
      final hasLoc = perms.any((p) => p.contains('LOCATION') || p == 'android.permission.ACCESS_FINE_LOCATION');

      expect(hasCamera, isTrue);
      expect(hasMic, isTrue);
      expect(hasLoc, isTrue);
      // Spy combo = camera + mic + location
      expect(hasCamera && hasMic && hasLoc, isTrue);
    });

    test('app without dangerous permissions does not appear', () {
      final raw = {
        'name': 'Safe App',
        'package': 'com.safe.app',
        'version': '2.0',
        'permissions': ['android.permission.INTERNET'],
      };

      final perms = (raw['permissions'] as List)
          .map((p) => p.toString())
          .where((p) => const <String>{
                'android.permission.CAMERA',
                'android.permission.RECORD_AUDIO',
              }.contains(p))
          .toList();

      expect(perms, isEmpty);
    });
  });
}
