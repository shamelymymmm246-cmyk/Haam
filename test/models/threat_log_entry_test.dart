import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/threat_log_entry.dart';

void main() {
  group('ThreatLogEntry', () {
    test('creates entry with all fields', () {
      final entry = ThreatLogEntry(
        id: '1',
        domain: 'bad.example.com',
        category: ThreatCategory.malware,
        timestamp: DateTime(2024, 1, 1),
        isBlocked: true,
      );
      expect(entry.id, '1');
      expect(entry.domain, 'bad.example.com');
      expect(entry.category, ThreatCategory.malware);
      expect(entry.isBlocked, isTrue);
    });

    test('categoryLabel returns correct Arabic labels', () {
      expect(ThreatCategory.ad.categoryLabel, 'إعلان');
      expect(ThreatCategory.tracker.categoryLabel, 'متتبّع');
      expect(ThreatCategory.malware.categoryLabel, 'ضار');
      expect(ThreatCategory.phishing.categoryLabel, 'تصيّد');
      expect(ThreatCategory.spyware.categoryLabel, 'تجسّس');
      expect(ThreatCategory.unknown.categoryLabel, 'غير معروف');
    });
  });
}
