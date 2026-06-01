import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import 'package:haam_counter/models/dns_status.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/services/apps_collector.dart';
import 'package:haam_counter/services/device_integrity_collector.dart';
import 'package:haam_counter/services/dns_service.dart';
import 'package:haam_counter/services/network_collector.dart';
import 'package:haam_counter/services/network_devices_collector.dart';
import 'package:haam_counter/services/notification_manager.dart';
import 'package:haam_counter/services/rule_engine.dart';

const _kBgTaskName       = 'haam_security_scan';
const _kPeriodicTaskId   = 'haam_periodic_scan';
const _kLastHostCountKey = 'last_known_host_count';

/// مفتاح لتخزين آخر حالة DNS معروفة من فحص المقدّمة.
/// يُستخدم في الخلفية لأن قنوات المنصة المخصصة قد لا تكون متاحة هناك.
const kCachedDnsEncryptedKey = 'cached_dns_encrypted';

/// نقطة دخول WorkManager — يجب أن تكون دالة علوية (top-level).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await NotificationManager.initialize();

      final storage   = const FlutterSecureStorage();
      final network   = NetworkCollector();
      final dns       = DnsService();
      final apps      = AppsCollector();
      final integrity = DeviceIntegrityCollector();
      final devices   = NetworkDevicesCollector();

      // جمع الإشارات — كل collector يُعيد null/قيمة آمنة عند الفشل
      final networkInfo   = await network.collect();
      final dnsStatus     = await dns.checkStatus();
      final integrityData = await integrity.collect();
      final flaggedApps   = await apps.collect();
      final hostsCount    = await devices.scanActiveHosts(networkInfo?.gateway);

      // DNS: إذا أعاد الـ channel "unknown" (لأنه غير مسجَّل في الخلفية)،
      // نرجع للقيمة المخزَّنة من آخر فحص في المقدّمة لتجنّب إنذار زائف.
      final isDnsEncrypted = dnsStatus.mode != DnsMode.unknown
          ? dnsStatus.isEncrypted
          : (await storage.read(key: kCachedDnsEncryptedKey)) == 'true';

      // أجهزة جديدة على الشبكة — مقارنة بآخر عدد مخزَّن
      final storedHosts = await storage.read(key: _kLastHostCountKey);
      await storage.write(key: _kLastHostCountKey, value: '$hostsCount');
      final newDevices = storedHosts != null &&
          hostsCount > (int.tryParse(storedHosts) ?? 0);

      final state = SecurityState(
        networkInfo:                 networkInfo,
        isDnsEncrypted:              isDnsEncrypted,
        hasActiveVpn:                dnsStatus.hasActiveVpn,
        activeHostsCount:            hostsCount,
        newDevicesDetected:          newDevices,
        appsWithDangerousPermsCount: flaggedApps.length,
        flaggedApps:                 flaggedApps,
        deviceIntegrity:             integrityData,
        lastUpdated:                 DateTime.now(),
      );

      final assessment = RuleEngine().evaluate(state);
      if (assessment.triggeredRules.isEmpty) return true;

      final reasonSummary = assessment.triggeredRules.map((r) => r.reason).join(' · ');
      final actionSummary = assessment.triggeredRules.first.suggestedAction;

      await NotificationManager.maybeNotify(
        riskScore:        assessment.totalRisk,
        triggeredRuleIds: assessment.triggeredRules.map((r) => r.id).toList(),
        reasonSummary:    reasonSummary,
        actionSummary:    actionSummary,
      );
    } catch (_) {
      // الفشل الصامت أفضل من إسقاط مهمة WorkManager وتحديد الوقت لها
    }
    return true;
  });
}

class BackgroundService {
  static const _periodicTaskId = _kPeriodicTaskId;

  /// يُهيّئ WorkManager بالـ dispatcher — استدعِه مرة واحدة في main().
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  /// يُسجّل مهمة دورية كل 15 دقيقة (الحد الأدنى لـ WorkManager على Android).
  /// يحتفظ بالمهمة الموجودة إذا كانت مسجَّلة بالفعل.
  static Future<void> registerPeriodicScan() async {
    await Workmanager().registerPeriodicTask(
      _periodicTaskId,
      _kBgTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// يُلغي جميع المهام الخلفية المسجَّلة.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
