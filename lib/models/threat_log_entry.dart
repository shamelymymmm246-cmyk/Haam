enum ThreatCategory { ad, tracker, malware, phishing, spyware, unknown }

extension ThreatCategoryExt on ThreatCategory {
  String get categoryLabel {
    switch (this) {
      case ThreatCategory.ad:       return 'إعلان';
      case ThreatCategory.tracker:  return 'متتبّع';
      case ThreatCategory.malware:  return 'ضار';
      case ThreatCategory.phishing: return 'تصيّد';
      case ThreatCategory.spyware:  return 'تجسّس';
      case ThreatCategory.unknown:  return 'غير معروف';
    }
  }
}

class ThreatLogEntry {
  final String id;
  final String domain;
  final ThreatCategory category;
  final DateTime timestamp;
  final bool isBlocked;

  const ThreatLogEntry({
    required this.id,
    required this.domain,
    required this.category,
    required this.timestamp,
    this.isBlocked = true,
  });

  String get categoryLabel => category.categoryLabel;
}
