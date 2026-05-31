enum EncryptionType { none, wep, wpa, wpa2, wpa3, eap, owe, unknown }

class AppSecurityInfo {
  final String name;
  final String package;
  final String version;
  final List<String> dangerousPerms;
  final bool hasSpyCombo; // كاميرا + مايك + موقع معاً

  const AppSecurityInfo({
    required this.name,
    required this.package,
    required this.version,
    required this.dangerousPerms,
    required this.hasSpyCombo,
  });
}

class NetworkInfo {
  final String? ssid;
  final String? bssid;
  final String? gateway;
  final String? subnetMask;
  final bool isOpenNetwork;
  final EncryptionType encryptionType;
  final int? signal; // dBm
  final int? frequency; // MHz
  final bool hasSystemProxy;

  const NetworkInfo({
    this.ssid,
    this.bssid,
    this.gateway,
    this.subnetMask,
    required this.isOpenNetwork,
    required this.encryptionType,
    this.signal,
    this.frequency,
    required this.hasSystemProxy,
  });

  String get encryptionLabel {
    switch (encryptionType) {
      case EncryptionType.none:    return 'مفتوحة (بدون تشفير)';
      case EncryptionType.wep:     return 'WEP (ضعيف)';
      case EncryptionType.wpa:     return 'WPA';
      case EncryptionType.wpa2:    return 'WPA2';
      case EncryptionType.wpa3:    return 'WPA3 (الأحدث)';
      case EncryptionType.eap:     return 'WPA-EAP (مؤسسي)';
      case EncryptionType.owe:     return 'OWE (مشفّر-مفتوح)';
      case EncryptionType.unknown: return 'غير معروف';
    }
  }

  String? get signalLabel {
    if (signal == null) return null;
    if (signal! >= -50) return 'ممتاز';
    if (signal! >= -65) return 'جيد';
    if (signal! >= -75) return 'مقبول';
    return 'ضعيف';
  }

  String? get bandLabel {
    if (frequency == null) return null;
    if (frequency! >= 5000) return '5 GHz';
    if (frequency! >= 2400) return '2.4 GHz';
    return null;
  }
}

class DeviceIntegrity {
  final bool isRooted;
  final bool isEmulator;

  const DeviceIntegrity({
    required this.isRooted,
    required this.isEmulator,
  });
}

class SecurityState {
  final NetworkInfo? networkInfo;
  final bool isDnsEncrypted;
  final bool hasActiveVpn;
  final int activeHostsCount;
  final bool newDevicesDetected;
  final int appsWithDangerousPermsCount;
  final List<AppSecurityInfo> flaggedApps;
  final DeviceIntegrity? deviceIntegrity;
  final DateTime lastUpdated;
  // المرحلة 5: كاشف الشذوذ
  final double anomalyScore;        // 0.0–1.0 — درجة الشذوذ
  final int    anomalySampleCount;  // عدد الملاحظات في خط الأساس

  const SecurityState({
    this.networkInfo,
    required this.isDnsEncrypted,
    required this.hasActiveVpn,
    required this.activeHostsCount,
    required this.newDevicesDetected,
    required this.appsWithDangerousPermsCount,
    required this.flaggedApps,
    this.deviceIntegrity,
    required this.lastUpdated,
    this.anomalyScore       = 0.0,
    this.anomalySampleCount = 0,
  });

  factory SecurityState.empty() => SecurityState(
    isDnsEncrypted: false,
    hasActiveVpn: false,
    activeHostsCount: 0,
    newDevicesDetected: false,
    appsWithDangerousPermsCount: 0,
    flaggedApps: const [],
    lastUpdated: DateTime.now(),
  );

  bool get hasSystemProxy => networkInfo?.hasSystemProxy ?? false;

  int get spyAppsCount => flaggedApps.where((a) => a.hasSpyCombo).length;
}
