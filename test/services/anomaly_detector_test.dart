import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/services/anomaly_detector.dart';

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

SecurityState _makeState({
  int hosts = 3,
  int flaggedApps = 2,
  bool openNetwork = false,
  bool dnsEncrypted = true,
  bool hasVpn = false,
  int signal = -60,
}) {
  return SecurityState(
    networkInfo: NetworkInfo(
      isOpenNetwork: openNetwork,
      encryptionType: openNetwork ? EncryptionType.none : EncryptionType.wpa2,
      hasSystemProxy: false,
      signal: signal,
    ),
    isDnsEncrypted: dnsEncrypted,
    hasActiveVpn: hasVpn,
    activeHostsCount: hosts,
    newDevicesDetected: false,
    appsWithDangerousPermsCount: flaggedApps,
    flaggedApps: [],
    lastUpdated: DateTime.now(),
  );
}

void main() {
  group('AnomalyDetector', () {
    late AnomalyDetector detector;
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      detector = AnomalyDetector(storage: storage);
    });

    test('initially has no baseline', () {
      expect(detector.sampleCount, 0);
      expect(detector.hasBaseline, isFalse);
    });

    test('loadBaseline restores saved state', () async {
      await storage.write(key: 'anomaly_baseline_v1', value: '{"count":3,"means":[2.0,1.0,0.0,0.0,0.0,-60.0],"m2s":[0.0,0.0,0.0,0.0,0.0,0.0]}');
      await detector.loadBaseline();
      expect(detector.sampleCount, 3);
      expect(detector.hasBaseline, isFalse);
    });

    test('loadBaseline handles invalid data gracefully', () async {
      await storage.write(key: 'anomaly_baseline_v1', value: 'not-json');
      await detector.loadBaseline();
      expect(detector.sampleCount, 0);
    });

    test('returns 0.0 score before enough samples', () async {
      final state = _makeState();
      for (int i = 0; i < 4; i++) {
        final score = await detector.observe(state);
        expect(score, 0.0);
      }
      expect(detector.hasBaseline, isFalse);
    });

    test('returns non-zero score after enough samples with different state', () async {
      for (int i = 0; i < 5; i++) {
        await detector.observe(_makeState(hosts: 3, flaggedApps: 2));
      }
      expect(detector.hasBaseline, isTrue);

      final score = await detector.observe(_makeState(hosts: 15, flaggedApps: 8));
      expect(score, greaterThan(0.0));
    });

    test('returns low score for similar states', () async {
      for (int i = 0; i < 6; i++) {
        await detector.observe(_makeState(hosts: 3, flaggedApps: 2));
      }

      final score = await detector.observe(_makeState(hosts: 3, flaggedApps: 2));
      expect(score, lessThan(0.5));
    });

    test('persists and reloads baseline', () async {
      for (int i = 0; i < 7; i++) {
        await detector.observe(_makeState(hosts: 3, flaggedApps: 2));
      }

      final freshDetector = AnomalyDetector(storage: storage);
      await freshDetector.loadBaseline();
      expect(freshDetector.sampleCount, 7);
      expect(freshDetector.hasBaseline, isTrue);
    });

    test('toFeatures produces correct vector', () async {
      final state = SecurityState(
        networkInfo: NetworkInfo(
          isOpenNetwork: true,
          encryptionType: EncryptionType.none,
          hasSystemProxy: false,
          signal: -75,
        ),
        isDnsEncrypted: false,
        hasActiveVpn: true,
        activeHostsCount: 5,
        newDevicesDetected: false,
        appsWithDangerousPermsCount: 3,
        flaggedApps: [],
        lastUpdated: DateTime.now(),
      );

      await detector.observe(state);
      expect(detector.sampleCount, 1);
    });
  });
}
