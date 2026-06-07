import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/models/threat_log_entry.dart';
import 'package:haam_counter/services/apps_collector.dart';
import 'package:haam_counter/services/background_service.dart' show kCachedDnsEncryptedKey;
import 'package:haam_counter/services/device_integrity_collector.dart';
import 'package:haam_counter/services/dns_service.dart';
import 'package:haam_counter/services/ldf_service.dart';
import 'package:haam_counter/services/network_collector.dart';
import 'package:haam_counter/services/network_devices_collector.dart';
import 'package:haam_counter/services/anomaly_detector.dart';
import 'package:haam_counter/services/rule_engine.dart';
import 'package:haam_counter/services/threat_log_service.dart';

enum CollectorPhase { idle, collectingNetwork, collectingApps, scanningDevices, done }

const _kLastHostCountKey = 'last_known_host_count';

class SecurityStateProvider extends ChangeNotifier {
  SecurityState _state = SecurityState.empty();
  RiskAssessment _riskAssessment = RiskAssessment.empty();
  bool _loading = false;
  String? _error;
  CollectorPhase _phase = CollectorPhase.idle;

  SecurityState get state => _state;
  RiskAssessment get riskAssessment => _riskAssessment;
  bool get loading => _loading;
  String? get error => _error;
  CollectorPhase get phase => _phase;

  final _dnsService       = DnsService();
  final _network          = NetworkCollector();
  final _apps             = AppsCollector();
  final _integrity        = DeviceIntegrityCollector();
  final _devices          = NetworkDevicesCollector();
  final _ruleEngine       = RuleEngine();
  final _anomalyDetector  = AnomalyDetector();
  final _storage          = const FlutterSecureStorage();
  final _systemChannel    = const MethodChannel('com.haam.security/system');
  final _threatLogService = ThreatLogService();
  bool _anomalyReady      = false;

  /// هل اكتشف ARP spoofing؟ (يُحدَّث أثناء الفحص)
  bool _arpSpoofed = false;
  bool get arpSpoofed => _arpSpoofed;

  Future<void> refresh() async {
    if (_loading) return;

    _loading = true;
    _error   = null;
    _phase   = CollectorPhase.collectingNetwork;
    notifyListeners();

    try {
      if (!_anomalyReady) {
        await _anomalyDetector.loadBaseline();
        _anomalyReady = true;
      }

      final networkFuture   = _network.collect();
      final dnsFuture       = _dnsService.checkStatus();
      final integrityFuture = _integrity.collect();

      final networkInfo = await networkFuture;
      final dnsStatus   = await dnsFuture;
      final integrity   = await integrityFuture;

      _phase = CollectorPhase.collectingApps;
      notifyListeners();

      final flaggedApps = await _apps.collect();

      _phase = CollectorPhase.scanningDevices;
      notifyListeners();

      final hostsCount = await _devices.scanActiveHosts(networkInfo?.gateway);

      final newDevicesDetected = await _checkNewDevices(hostsCount);

      // المرحلة 4 — فحوص إضافية: ARP spoofing + سجل التهديدات
      try {
        _arpSpoofed = await _systemChannel.invokeMethod<bool>('checkArpSpoofing') ?? false;
      } catch (_) {
        _arpSpoofed = false;
      }

      // سجل المحجوب من LDF في ThreatLogService
      try {
        final ldfStatus = await LdfService().getStatus();
        if (ldfStatus.blockedQueries > 0) {
          final recentLog = await _threatLogService.getLog();
          final lastBlockedCount = recentLog
              .where((e) => e.isBlocked)
              .length;
          // أضف دفعة جديدة إذا كان العدّاد ازداد
          if (ldfStatus.blockedQueries.toInt() > lastBlockedCount) {
            await _threatLogService.addEntry(
              ThreatLogEntry(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                domain: 'blocklist.internal',
                category: ThreatCategory.ad,
                timestamp: DateTime.now(),
                isBlocked: true,
              ),
            );
          }
        }
      } catch (_) {}

      // حالة أولية بدون درجة شذوذ — للتغذية في الكاشف
      final prelimState = SecurityState(
        networkInfo:                 networkInfo,
        isDnsEncrypted:              dnsStatus.isEncrypted,
        hasActiveVpn:                dnsStatus.hasActiveVpn,
        activeHostsCount:            hostsCount,
        newDevicesDetected:          newDevicesDetected,
        appsWithDangerousPermsCount: flaggedApps.length,
        flaggedApps:                 flaggedApps,
        deviceIntegrity:             integrity,
        lastUpdated:                 DateTime.now(),
        arpSpoofed:                  _arpSpoofed,
      );

      final anomalyScore = await _anomalyDetector.observe(prelimState);

      _state = SecurityState(
        networkInfo:                 networkInfo,
        isDnsEncrypted:              dnsStatus.isEncrypted,
        hasActiveVpn:                dnsStatus.hasActiveVpn,
        activeHostsCount:            hostsCount,
        newDevicesDetected:          newDevicesDetected,
        appsWithDangerousPermsCount: flaggedApps.length,
        flaggedApps:                 flaggedApps,
        deviceIntegrity:             integrity,
        lastUpdated:                 DateTime.now(),
        anomalyScore:                anomalyScore,
        anomalySampleCount:          _anomalyDetector.sampleCount,
        arpSpoofed:                  _arpSpoofed,
      );

      _riskAssessment = _ruleEngine.evaluate(_state);

      // خزّن حالة DNS حتى تستخدمها مهمة الخلفية عند فشل قناة المنصة
      await _storage.write(
        key: kCachedDnsEncryptedKey,
        value: _state.isDnsEncrypted.toString(),
      );

      _phase = CollectorPhase.done;
    } catch (e) {
      _error = 'فشل جمع المؤشرات الأمنية.';
      _phase = CollectorPhase.idle;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> _checkNewDevices(int currentCount) async {
    final stored = await _storage.read(key: _kLastHostCountKey);
    await _storage.write(key: _kLastHostCountKey, value: '$currentCount');

    if (stored == null) return false;
    final lastCount = int.tryParse(stored) ?? 0;
    return currentCount > lastCount;
  }

  String get phaseLabel {
    switch (_phase) {
      case CollectorPhase.collectingNetwork: return 'جاري فحص الشبكة...';
      case CollectorPhase.collectingApps:   return 'جاري تحليل التطبيقات...';
      case CollectorPhase.scanningDevices:  return 'جاري مسح أجهزة الشبكة...';
      case CollectorPhase.done:             return 'اكتمل الفحص';
      case CollectorPhase.idle:             return '';
    }
  }

  /// هل اكتمل فحص واحد على الأقل (لدينا بيانات حقيقية لعرضها)؟
  bool get hasScanned => _phase == CollectorPhase.done || _state.activeHostsCount > 0
      || _state.networkInfo != null || _riskAssessment.triggeredRules.isNotEmpty;

  /// درجة الأمان 0–100 مشتقّة من محرك القواعد (100 = آمن تماماً).
  int get securityScore => (100 - _riskAssessment.totalRisk).clamp(0, 100);

  /// لون الدرجة حسب المستوى.
  RiskLevel get level => _riskAssessment.level;
}
