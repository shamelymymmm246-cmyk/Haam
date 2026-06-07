import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/protection_event.dart';

void main() {
  group('ProtectionEvent', () {
    test('creates event with all fields', () {
      final event = ProtectionEvent(
        id: 'evt_1',
        type: ProtectionEventType.ldfBlocked,
        title: 'تم حجب نطاق ضار',
        description: 'حُجب bad.example.com بواسطة فلتر DNS',
        suggestedAction: 'لا تحتاج لإجراء — الحجب تلقائي',
        timestamp: DateTime(2024, 1, 1),
        isWarning: false,
      );

      expect(event.id, 'evt_1');
      expect(event.type, ProtectionEventType.ldfBlocked);
      expect(event.title, 'تم حجب نطاق ضار');
      expect(event.isWarning, isFalse);
    });

    test('typeLabel returns correct Arabic labels', () {
      expect(ProtectionEventType.ldfBlocked.typeLabel, 'حجب DNS');
      expect(ProtectionEventType.dnsLeak.typeLabel, 'DNS غير مشفّر');
      expect(ProtectionEventType.networkChanged.typeLabel, 'تغيّر الشبكة');
      expect(ProtectionEventType.suspiciousApp.typeLabel, 'تطبيق مشبوه');
      expect(ProtectionEventType.deviceIntegrity.typeLabel, 'سلامة الجهاز');
      expect(ProtectionEventType.newDevice.typeLabel, 'جهاز جديد');
    });

    test('can create warning event', () {
      final event = ProtectionEvent(
        id: 'evt_2',
        type: ProtectionEventType.suspiciousApp,
        title: 'تطبيق مشبوه',
        description: 'تطبيق جديد يملك أذونات خطرة',
        suggestedAction: 'راجع الأذونات',
        timestamp: DateTime.now(),
        isWarning: true,
      );
      expect(event.isWarning, isTrue);
    });
  });
}
