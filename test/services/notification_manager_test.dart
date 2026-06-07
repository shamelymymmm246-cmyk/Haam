import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/services/notification_manager.dart';

class MockStorageNotif extends FlutterSecureStorage {
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
}

void main() {
  group('NotificationSensitivity', () {
    test('off has highest threshold (no notifications)', () {
      expect(NotificationSensitivity.off.threshold, 101);
    });

    test('low notifies only for danger (>50)', () {
      expect(NotificationSensitivity.low.threshold, 51);
    });

    test('medium notifies for warning and danger (>30)', () {
      expect(NotificationSensitivity.medium.threshold, 31);
    });

    test('high notifies for any issue (>20)', () {
      expect(NotificationSensitivity.high.threshold, 21);
    });
  });

  group('NotificationManager', () {
    late MockStorageNotif mockStorage;

    setUp(() {
      NotificationManager.testReset();
      mockStorage = MockStorageNotif();
      NotificationManager.setTestStorage(mockStorage);
    });

    test('default background is enabled', () async {
      final enabled = await NotificationManager.isBackgroundEnabled();
      expect(enabled, isTrue);
    });

    test('can set and get sensitivity', () async {
      await NotificationManager.setSensitivity(NotificationSensitivity.low);
      final s = await NotificationManager.getSensitivity();
      expect(s, NotificationSensitivity.low);
    });

    test('default sensitivity is medium', () async {
      final s = await NotificationManager.getSensitivity();
      expect(s, NotificationSensitivity.medium);
    });

    test('can disable background monitoring', () async {
      await NotificationManager.setBackgroundEnabled(false);
      final enabled = await NotificationManager.isBackgroundEnabled();
      expect(enabled, isFalse);
    });
  });
}
