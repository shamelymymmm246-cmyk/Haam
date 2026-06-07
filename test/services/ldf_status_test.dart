import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/ldf_status.dart';

void main() {
  group('LdfStatus', () {
    test('idle factory creates stopped state', () {
      final idle = LdfStatus.idle();
      expect(idle.running, isFalse);
      expect(idle.totalQueries, 0);
      expect(idle.blockedQueries, 0);
      expect(idle.allowedQueries, 0);
    });

    test('allowedQueries is total minus blocked', () {
      final status = LdfStatus(running: true, totalQueries: 100, blockedQueries: 30);
      expect(status.allowedQueries, 70);
    });

    test('allowedQueries clamped to 0', () {
      final status = LdfStatus(running: true, totalQueries: 10, blockedQueries: 20);
      expect(status.allowedQueries, 0);
    });

    test('fromMap parses map correctly', () {
      final map = <dynamic, dynamic>{
        'running': true,
        'totalQueries': 50,
        'blockedQueries': 12,
      };
      final status = LdfStatus.fromMap(map);
      expect(status.running, isTrue);
      expect(status.totalQueries, 50);
      expect(status.blockedQueries, 12);
    });

    test('fromMap handles missing keys', () {
      final map = <dynamic, dynamic>{};
      final status = LdfStatus.fromMap(map);
      expect(status.running, isFalse);
      expect(status.totalQueries, 0);
      expect(status.blockedQueries, 0);
    });
  });
}
