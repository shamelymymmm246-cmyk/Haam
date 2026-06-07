import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/models/security_state.dart';

class SecurityRule {
  final String id;
  final bool Function(SecurityState) condition;
  final int riskWeight;
  final String reason;
  final String suggestedAction;

  const SecurityRule({
    required this.id,
    required this.condition,
    required this.riskWeight,
    required this.reason,
    required this.suggestedAction,
  });
}

class RuleEngine {
  static final List<SecurityRule> rules = [
    SecurityRule(
      id: 'R1',
      condition: (s) => s.networkInfo?.isOpenNetwork == true,
      riskWeight: 35,
      reason: 'بياناتك مكشوفة على هذه الشبكة المفتوحة',
      suggestedAction: 'فعّل VPN أو تجنّب البيانات الحساسة الآن',
    ),
    SecurityRule(
      id: 'R2',
      condition: (s) => !s.isDnsEncrypted,
      riskWeight: 20,
      reason: 'مزوّد الإنترنت يرى المواقع التي تزورها',
      suggestedAction: 'فعّل DNS المشفّر (DoH) من إعدادات الشبكة',
    ),
    SecurityRule(
      id: 'R3',
      condition: (s) => s.newDevicesDetected,
      riskWeight: 10,
      reason: 'جهاز جديد ظهر على شبكتك منذ آخر فحص',
      suggestedAction: 'تحقّق أنه جهاز تعرفه — إذا لم تعرفه فقد يكون دخيلاً',
    ),
    SecurityRule(
      id: 'R4',
      condition: (s) => s.spyAppsCount > 0,
      riskWeight: 25,
      reason: 'تطبيق لديه مجموعة أذونات تجسّس محتملة (كاميرا + مايك + موقع)',
      suggestedAction: 'راجع أذونات هذا التطبيق من إعدادات الهاتف',
    ),
    SecurityRule(
      id: 'R5',
      condition: (s) => s.deviceIntegrity?.isRooted == true,
      riskWeight: 30,
      reason: 'حماية النظام منخفضة على جهاز مروّت',
      suggestedAction: 'تجنّب تخزين بيانات حساسة على هذا الجهاز',
    ),
    SecurityRule(
      id: 'R6',
      condition: (s) => s.anomalySampleCount >= 5 && s.anomalyScore > 0.75,
      riskWeight: 15,
      reason: 'نمط أمني غير مألوف رصده كاشف الشذوذ',
      suggestedAction: 'راجع المؤشرات الأمنية — قد يكون هناك تغيّر غير اعتيادي في بيئتك',
    ),
    // R7 — المرحلة 4 (التحصين العميق): تلاعب/تحليل فعّال على بيئة التشغيل.
    // إشارة حرجة لأنها تُقوّض ضمانات التشفير (هوكينغ/تتبّع/توقيع غير مطابق/APK معدّل).
    SecurityRule(
      id: 'R7',
      condition: (s) => s.deviceIntegrity?.hasCriticalTamper == true,
      riskWeight: 35,
      reason: 'رُصد تلاعب أو أداة تحليل فعّالة على بيئة التشغيل (هوكينغ/تتبّع/APK معدّل/توقيع غير مطابق)',
      suggestedAction: 'أغلق أدوات التحليل وأعد التشغيل على جهاز نظيف — تُعطَّل الخزنة احترازياً',
    ),
    // R8 — المرحلة 4: إشارات بيئة مشبوهة غير حرجة
    // (Magisk مخفي، تلاعب بالساعة، Root مخفي)
    SecurityRule(
      id: 'R8',
      condition: (s) =>
          (s.deviceIntegrity?.isMagiskHidden == true) ||
          (s.deviceIntegrity?.isClockTampered == true),
      riskWeight: 20,
      reason: 'رُصدت إشارات بيئة مشبوهة (Magisk مخفي أو تلاعب بالساعة)',
      suggestedAction: 'راجع سلامة جهازك — هذه الإشارات قد تعني محاولة إخفاء أدوات تعديل',
    ),
  ];

  RiskAssessment evaluate(SecurityState state) {
    final triggered = rules
        .where((r) => r.condition(state))
        .map((r) => RuleResult(
              id: r.id,
              reason: r.reason,
              suggestedAction: r.suggestedAction,
              riskWeight: r.riskWeight,
            ))
        .toList();

    final rawTotal = triggered.fold<int>(0, (sum, r) => sum + r.riskWeight);
    final total = rawTotal.clamp(0, 100);

    final level = total <= 20
        ? RiskLevel.safe
        : total <= 50
            ? RiskLevel.warning
            : RiskLevel.danger;

    return RiskAssessment(
      totalRisk: total,
      level: level,
      triggeredRules: triggered,
    );
  }
}
