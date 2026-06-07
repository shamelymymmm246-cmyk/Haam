enum ProtectionEventType {
  ldfBlocked,
  dnsLeak,
  networkChanged,
  suspiciousApp,
  deviceIntegrity,
  newDevice,
}

extension ProtectionEventTypeExt on ProtectionEventType {
  String get typeLabel {
    switch (this) {
      case ProtectionEventType.ldfBlocked:       return 'حجب DNS';
      case ProtectionEventType.dnsLeak:          return 'DNS غير مشفّر';
      case ProtectionEventType.networkChanged:   return 'تغيّر الشبكة';
      case ProtectionEventType.suspiciousApp:    return 'تطبيق مشبوه';
      case ProtectionEventType.deviceIntegrity:  return 'سلامة الجهاز';
      case ProtectionEventType.newDevice:        return 'جهاز جديد';
    }
  }
}

class ProtectionEvent {
  final String id;
  final ProtectionEventType type;
  final String title;
  final String description;
  final String suggestedAction;
  final DateTime timestamp;
  final bool isWarning;

  const ProtectionEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.suggestedAction,
    required this.timestamp,
    this.isWarning = false,
  });

  String get typeLabel => type.typeLabel;
}
