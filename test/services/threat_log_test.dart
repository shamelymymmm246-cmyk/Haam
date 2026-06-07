import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/models/threat_log_entry.dart';
import 'package:haam_counter/services/threat_log_service.dart';

class MockStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('ThreatLogService', () {
    late ThreatLogService service;
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      service = ThreatLogService(storage: storage);
    });

    test('getLog returns empty list when no data', () async {
      final log = await service.getLog();
      expect(log, isEmpty);
    });

    test('addEntry stores and retrieves entries', () async {
      await service.addEntry(ThreatLogEntry(
        id: '1',
        domain: 'ads.example.com',
        category: ThreatCategory.ad,
        timestamp: DateTime(2024, 1, 1),
      ));

      final log = await service.getLog();
      expect(log.length, 1);
      expect(log[0].domain, 'ads.example.com');
      expect(log[0].category, ThreatCategory.ad);
      expect(log[0].isBlocked, isTrue);
    });

    test('entries are returned in reverse chronological order (newest first)', () async {
      await service.addEntry(ThreatLogEntry(
        id: '1', domain: 'first.com', category: ThreatCategory.ad,
        timestamp: DateTime(2024, 1, 1),
      ));
      await service.addEntry(ThreatLogEntry(
        id: '2', domain: 'second.com', category: ThreatCategory.tracker,
        timestamp: DateTime(2024, 1, 2),
      ));

      final log = await service.getLog();
      expect(log.length, 2);
      expect(log[0].id, '2');
      expect(log[1].id, '1');
    });

    test('totalBlockedCount returns correct count', () async {
      await service.addEntry(ThreatLogEntry(
        id: '1', domain: 'a.com', category: ThreatCategory.ad, timestamp: DateTime.now(),
      ));
      await service.addEntry(ThreatLogEntry(
        id: '2', domain: 'b.com', category: ThreatCategory.malware, timestamp: DateTime.now(),
      ));

      final count = await service.totalBlockedCount();
      expect(count, 2);
    });

    test('clear removes all entries', () async {
      await service.addEntry(ThreatLogEntry(
        id: '1', domain: 'a.com', category: ThreatCategory.ad, timestamp: DateTime.now(),
      ));
      await service.clear();

      final log = await service.getLog();
      expect(log, isEmpty);
    });

    test('handles all threat categories', () async {
      for (final cat in ThreatCategory.values) {
        await service.addEntry(ThreatLogEntry(
          id: '${cat.index}',
          domain: '${cat.name}.example.com',
          category: cat,
          timestamp: DateTime.now(),
        ));
      }

      final log = await service.getLog();
      expect(log.length, ThreatCategory.values.length);
      for (final cat in ThreatCategory.values) {
        expect(log.any((e) => e.category == cat), isTrue);
      }
    });

    test('each category has a non-empty Arabic label', () async {
      for (final cat in ThreatCategory.values) {
        expect(cat.categoryLabel, isNotEmpty);
      }
    });

    test('supports up to 200 entries (circular buffer)', () async {
      for (int i = 0; i < 250; i++) {
        await service.addEntry(ThreatLogEntry(
          id: '$i',
          domain: 'domain$i.com',
          category: ThreatCategory.ad,
          timestamp: DateTime.now(),
        ));
      }

      final log = await service.getLog();
      expect(log.length, 200);
    });

    test('persists and reloads across service instances', () async {
      await service.addEntry(ThreatLogEntry(
        id: '1', domain: 'tracker.com', category: ThreatCategory.tracker,
        timestamp: DateTime.now(),
      ));

      final freshService = ThreatLogService(storage: storage);
      final log = await freshService.getLog();
      expect(log.length, 1);
      expect(log[0].domain, 'tracker.com');
    });

    test('handles corrupted storage gracefully', () async {
      await storage.write(key: 'threat_log_v1', value: 'not-{{json');
      final log = await service.getLog();
      expect(log, isEmpty);
    });

    test('ThreatLogEntry model fields are correct', () {
      final entry = ThreatLogEntry(
        id: 'test-id',
        domain: 'malware.example.com',
        category: ThreatCategory.malware,
        timestamp: DateTime(2024, 6, 15, 10, 30),
        isBlocked: true,
      );

      expect(entry.id, 'test-id');
      expect(entry.domain, 'malware.example.com');
      expect(entry.category, ThreatCategory.malware);
      expect(entry.isBlocked, isTrue);
      expect(entry.categoryLabel, 'ضار');
    });
  });
}
