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

/// إشارات سلامة الجهاز وبيئة التشغيل (المرحلة 4 — التحصين العميق).
///
/// كل حقل إشارة حقيقية مجموعة من المنصّة الأصلية. الحقول الجديدة لها قيم
/// افتراضية آمنة حتى لا تتعطّل أماكن البناء القديمة، وحتى لا نُطلق إنذاراً
/// كاذباً عند تعذّر القياس (مبدأ الصدق: لا تلاعب = القيمة الآمنة).
class DeviceIntegrity {
  final bool isRooted;
  final bool isEmulator;
  // طبقة 4-ب — مقاومة التحليل (RASP)
  final bool isDebuggable;       // بناء قابل للتنقيح
  final bool isDebuggerAttached; // مُنقِّح متّصل الآن
  final bool isBeingTraced;      // TracerPid ≠ 0 (ptrace)
  final bool isFridaDetected;    // أثر Frida/هوكينغ
  final bool isXposedDetected;   // أثر Xposed/LSPosed
  final bool isAdbEnabled;       // ADB مفعّل في الإعدادات
  final bool isMockLocation;     // محاكاة الموقع
  // طبقة 4-أ — إثبات النزاهة
  final bool signatureValid;     // توقيع التطبيق مطابق للمرجع
  final bool installerTrusted;   // مُثبَّت من متجر موثوق
  final bool apkIntegrityValid;  // سلامة DEX/APK (4أ.4)
  // طبقة 4-ب.2 — إشارات Magisk مخفية
  final bool isMagiskHidden;     // Magisk Hide/DenyList (4ب.2)
  // طبقة 4-و.4 — كشف العبث بالساعة
  final bool isClockTampered;    // Clock tampering (4و.4)
  // طبقة 4-و.1 — دعم البصمة القوية
  final bool hasStrongBiometric; // BIOMETRIC_STRONG (4و.1)

  const DeviceIntegrity({
    required this.isRooted,
    required this.isEmulator,
    this.isDebuggable       = false,
    this.isDebuggerAttached = false,
    this.isBeingTraced      = false,
    this.isFridaDetected    = false,
    this.isXposedDetected   = false,
    this.isAdbEnabled       = false,
    this.isMockLocation     = false,
    this.signatureValid     = true,
    this.installerTrusted   = true,
    this.apkIntegrityValid  = true,
    this.isMagiskHidden     = false,
    this.isClockTampered    = false,
    this.hasStrongBiometric  = false,
  });

  /// إشارات حرجة تدلّ على تلاعب/تحليل فعّال يُقوّض ضمانات التشفير
  /// (هوكينغ، تتبّع، أو إعادة تغليف بتوقيع غير مطابق، أو DEX معدّل).
  bool get hasCriticalTamper =>
      isFridaDetected ||
      isXposedDetected ||
      isDebuggerAttached ||
      isBeingTraced ||
      !signatureValid ||
      !apkIntegrityValid;

  /// إشارات تخفض الثقة دون أن تكون حرجة (تحذير لا رفض).
  bool get hasWarningSignals =>
      isRooted || isEmulator || isDebuggable || isAdbEnabled ||
      isMockLocation || isMagiskHidden || isClockTampered;

  /// أسماء عربية مختصرة للإشارات المُفعّلة — للعرض والتعليل بصدق.
  List<String> get activeSignals {
    final s = <String>[];
    if (isFridaDetected)     s.add('Frida/هوكينغ');
    if (isXposedDetected)    s.add('Xposed');
    if (isDebuggerAttached)  s.add('مُنقِّح متّصل');
    if (isBeingTraced)       s.add('تتبّع (ptrace)');
    if (!signatureValid)     s.add('توقيع غير مطابق');
    if (!apkIntegrityValid)  s.add('APK معدّل');
    if (isRooted)            s.add('Root');
    if (isEmulator)          s.add('محاكي');
    if (isDebuggable)        s.add('بناء تنقيح');
    if (isAdbEnabled)        s.add('ADB مفعّل');
    if (isMockLocation)      s.add('موقع مُحاكى');
    if (isMagiskHidden)      s.add('Magisk مخفي');
    if (isClockTampered)     s.add('تلاعب بالساعة');
    if (!installerTrusted)   s.add('مصدر غير موثوق');
    if (!hasStrongBiometric) s.add('بصمة غير قوية');
    return s;
  }
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
  // المرحلة 4: ARP spoofing (طبقة 4-د.5)
  final bool arpSpoofed;            // هل MAC الـ Gateway تغيّر؟

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
    this.arpSpoofed         = false,
  });

  factory SecurityState.empty() => SecurityState(
    isDnsEncrypted: false,
    hasActiveVpn: false,
    activeHostsCount: 0,
    newDevicesDetected: false,
    appsWithDangerousPermsCount: 0,
    flaggedApps: const [],
    lastUpdated: DateTime.now(),
    arpSpoofed: false,
  );

  bool get hasSystemProxy => networkInfo?.hasSystemProxy ?? false;

  int get spyAppsCount => flaggedApps.where((a) => a.hasSpyCombo).length;

  /// عدد التطبيقات التي تملك إذن الكاميرا أو المايك (بيانات حقيقية من فحص الأذونات).
  int get cameraMicAppsCount => flaggedApps
      .where((a) => a.dangerousPerms
          .any((p) => p.contains('CAMERA') || p.contains('RECORD_AUDIO')))
      .length;
}
