import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/ambient_background.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/shared/card_header.dart';

class SecurityOverviewScreen extends StatefulWidget {
  const SecurityOverviewScreen({super.key});

  @override
  State<SecurityOverviewScreen> createState() => _SecurityOverviewScreenState();
}

class _SecurityOverviewScreenState extends State<SecurityOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan() async {
    // اطلب إذن الموقع إذا لم يكن ممنوحاً — مطلوب لقراءة SSID على Android 9+
    final status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
    }
    if (!mounted) return;
    await context.read<SecurityStateProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('مؤشرات الأمان'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          Consumer<SecurityStateProvider>(
            builder: (_, p, __) => IconButton(
              icon: p.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.safeBlue),
                    )
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة الفحص',
              onPressed: p.loading ? null : _startScan,
            ),
          ),
        ],
      ),
      body: AmbientBackground(
        variant: AmbientVariant.topGlow,
        child: SafeArea(
          child: Consumer<SecurityStateProvider>(
            builder: (_, provider, __) {
              if (provider.loading && provider.state.lastUpdated.isBefore(
                  DateTime.now().subtract(const Duration(seconds: 1)))) {
                return _buildLoadingView(provider.phaseLabel);
              }
              return _buildContent(provider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.safeBlue),
          const SizedBox(height: 20),
          Text(
            label.isEmpty ? 'جاري الفحص...' : label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SecurityStateProvider provider) {
    final s = provider.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── شريط تقدم المرحلة الحالية ───────────────────────
          if (provider.loading)
            _PhaseBar(label: provider.phaseLabel)
                .animate()
                .fadeIn(duration: 300.ms),

          const SizedBox(height: 8),

          // ─── 0. بطاقة درجة الخطر (Rule Engine) ───────────────
          _RiskScoreCard(assessment: provider.riskAssessment)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 0ب. بطاقة كاشف الشذوذ (المرحلة 5) ───────────────
          _AnomalyCard(
            score:       s.anomalyScore,
            sampleCount: s.anomalySampleCount,
          ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 1. بطاقة الشبكة ─────────────────────────────────
          _NetworkCard(info: s.networkInfo)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 2. بطاقة الاتصال الآمن (DNS + VPN) ──────────────
          _ConnectionCard(
            isDnsEncrypted: s.isDnsEncrypted,
            hasVpn:         s.hasActiveVpn,
            hasProxy:       s.hasSystemProxy,
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 3. بطاقة أجهزة الشبكة ───────────────────────────
          _DevicesCard(count: s.activeHostsCount, isScanning: provider.loading)
              .animate()
              .fadeIn(delay: 160.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 4. بطاقة التطبيقات ──────────────────────────────
          _AppsCard(
            totalFlagged: s.appsWithDangerousPermsCount,
            spyApps:      s.spyAppsCount,
            flaggedApps:  s.flaggedApps,
          ).animate().fadeIn(delay: 240.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── 5. بطاقة سلامة الجهاز ───────────────────────────
          _IntegrityCard(integrity: s.deviceIntegrity)
              .animate()
              .fadeIn(delay: 320.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ─── ملاحظة الصدق ─────────────────────────────────────
          _HonestNote()
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة درجة الخطر — محرك القواعد
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _RiskScoreCard extends StatelessWidget {
  final RiskAssessment assessment;
  const _RiskScoreCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = assessment.level.color;
    final triggered = assessment.triggeredRules;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── رأس البطاقة: درجة + مستوى ─────────────────────────
          Row(
            children: [
              // دائرة الدرجة
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  color: color.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    '${assessment.totalRisk}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(assessment.level.icon, color: color, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          assessment.level.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      triggered.isEmpty
                          ? 'لم يُرصد تهديد في الوضع الحالي'
                          : '${triggered.length} ${triggered.length == 1 ? 'مشكلة' : 'مشاكل'} تستحق الانتباه',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // شريط تقدم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: assessment.totalRisk / 100,
                        minHeight: 5,
                        backgroundColor: AppColors.containerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0–20 آمن · 21–50 انتبه · 51+ خطر',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── قائمة القواعد المُحقَّقة ───────────────────────────
          if (triggered.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 12),
            ...triggered.map((r) => _RuleItem(rule: r)),
          ],
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final RuleResult rule;
  const _RuleItem({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شارة معرّف القاعدة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
            ),
            child: Text(
              rule.id,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.alertRed,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.reason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.safeBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rule.suggestedAction,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.safeBlue,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // وزن الخطر
          Text(
            '+${rule.riskWeight}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.alertRed.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// شريط تقدم المرحلة الحالية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PhaseBar extends StatelessWidget {
  final String label;
  const _PhaseBar({required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.safeBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة الشبكة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _NetworkCard extends StatelessWidget {
  final NetworkInfo? info;
  const _NetworkCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.wifi_rounded,
            title: 'الشبكة الحالية',
            iconColor: AppColors.safeBlue,
          ),
          const SizedBox(height: 14),
          if (info == null)
            const EmptyStateCard(message: 'غير متصل بشبكة واي فاي أو تعذّر القراءة.')
          else ...[
            InfoRow('الاسم (SSID)',      info!.ssid    ?? 'يتطلب إذن الموقع'),
            InfoRow('BSSID',            info!.bssid   ?? 'يتطلب إذن الموقع'),
            InfoRow('البوابة (Gateway)', info!.gateway ?? 'غير متوفر'),
            InfoRow('قناع الشبكة',       info!.subnetMask ?? 'غير متوفر'),
            InfoRow('التشفير',           info!.encryptionLabel,
                valueColor: info!.isOpenNetwork ? AppColors.alertRed : AppColors.activeMint),
            if (info!.signal != null)
              InfoRow('قوة الإشارة',
                  '${info!.signal} dBm  (${info!.signalLabel ?? ''})'),
            if (info!.bandLabel != null)
              InfoRow('التردد', info!.bandLabel!),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة الاتصال الآمن
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ConnectionCard extends StatelessWidget {
  final bool isDnsEncrypted;
  final bool hasVpn;
  final bool hasProxy;

  const _ConnectionCard({
    required this.isDnsEncrypted,
    required this.hasVpn,
    required this.hasProxy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.security_rounded,
            title: 'حماية الاتصال',
            iconColor: AppColors.activeMint,
          ),
          const SizedBox(height: 14),
          StatusBoolRow('DNS مشفّر',  isDnsEncrypted,
              trueNote:  'استعلاماتك محمية من التجسّس',
              falseNote: 'ISP يرى المواقع التي تزورها'),
          StatusBoolRow('VPN نشط',   hasVpn,
              trueNote:  'حركة البيانات مشفّرة عبر VPN',
              falseNote: 'لا يوجد VPN — بياناتك مكشوفة على الشبكة المحلية'),
          StatusBoolRow('Proxy نظام', hasProxy,
              trueNote:  'قد يُعيد توجيه حركتك لخادم وسيط',
              falseNote: 'لا يوجد proxy',
              trueIsWarning: true),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة أجهزة الشبكة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _DevicesCard extends StatelessWidget {
  final int count;
  final bool isScanning;
  const _DevicesCard({required this.count, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.devices_rounded,
            title: 'أجهزة الشبكة',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                isScanning ? '...' : '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: count > 10
                      ? AppColors.alertRed
                      : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isScanning
                      ? 'جاري مسح الأجهزة النشطة...'
                      : 'جهاز نشط اكتُشف بمسح TCP\n(يكتشف الأجهزة ذات البورتات المفتوحة فقط)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة التطبيقات
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AppsCard extends StatefulWidget {
  final int totalFlagged;
  final int spyApps;
  final List<AppSecurityInfo> flaggedApps;
  const _AppsCard({
    required this.totalFlagged,
    required this.spyApps,
    required this.flaggedApps,
  });

  @override
  State<_AppsCard> createState() => _AppsCardState();
}

class _AppsCardState extends State<_AppsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.apps_rounded,
            title: 'التطبيقات المثبّتة',
            iconColor: widget.spyApps > 0 ? AppColors.alertRed : AppColors.safeBlue,
          ),
          const SizedBox(height: 14),
          InfoRow('تطبيقات بأذونات خطرة', '${widget.totalFlagged}',
              valueColor: widget.totalFlagged > 5 ? AppColors.alertRed : null),
          InfoRow('تطبيقات بمجموعة "تجسّس"', '${widget.spyApps}',
              subtitle: 'كاميرا + مايك + موقع معاً',
              valueColor: widget.spyApps > 0 ? AppColors.alertRed : AppColors.activeMint),

          if (widget.flaggedApps.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.safeBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.safeBlue,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              ...widget.flaggedApps.take(20).map((app) => _AppEntry(app: app)),
            ],
          ],
        ],
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  final AppSecurityInfo app;
  const _AppEntry({required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, left: 8, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: app.hasSpyCombo ? AppColors.alertRed : AppColors.safeBlue,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (app.hasSpyCombo)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.alertRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.alertRed.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'تجسّس',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.alertRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  app.dangerousPerms
                      .map(_shortPermName)
                      .join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortPermName(String perm) {
    final map = {
      'android.permission.CAMERA':                   'كاميرا',
      'android.permission.RECORD_AUDIO':             'مايك',
      'android.permission.ACCESS_FINE_LOCATION':     'موقع دقيق',
      'android.permission.ACCESS_COARSE_LOCATION':   'موقع تقريبي',
      'android.permission.ACCESS_BACKGROUND_LOCATION': 'موقع خلفية',
      'android.permission.READ_CONTACTS':            'جهات اتصال',
      'android.permission.READ_CALL_LOG':            'سجل مكالمات',
      'android.permission.READ_SMS':                 'رسائل SMS',
      'android.permission.READ_PHONE_STATE':         'حالة الهاتف',
      'android.permission.PROCESS_OUTGOING_CALLS':   'مكالمات صادرة',
      'android.permission.SEND_SMS':                 'إرسال SMS',
      'android.permission.RECEIVE_SMS':              'استقبال SMS',
      'android.permission.BODY_SENSORS':             'مستشعرات جسم',
      'android.permission.READ_EXTERNAL_STORAGE':    'ملفات',
    };
    return map[perm] ?? perm.split('.').last;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة سلامة الجهاز
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _IntegrityCard extends StatelessWidget {
  final DeviceIntegrity? integrity;
  const _IntegrityCard({required this.integrity});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            icon: Icons.verified_user_rounded,
            title: 'سلامة الجهاز',
            iconColor: AppColors.tertiary,
          ),
          const SizedBox(height: 14),
          if (integrity == null)
            const EmptyStateCard(message: 'تعذّر فحص سلامة الجهاز.')
          else ...[
            StatusBoolRow(
              'الجهاز مروّت (Rooted)',
              integrity!.isRooted,
              trueNote:  'حماية النظام منخفضة — تجنّب تخزين بيانات حساسة',
              falseNote: 'لا أثر لـ root في المسارات المعروفة',
              trueIsWarning: true,
            ),
            StatusBoolRow(
              'محاكي (Emulator)',
              integrity!.isEmulator,
              trueNote:  'يعمل على محاكي — بعض الميزات قد لا تعمل',
              falseNote: 'جهاز حقيقي',
              trueIsWarning: true,
            ),
            // المرحلة 4 — طبقة 4-ب: مقاومة التحليل (RASP)
            StatusBoolRow(
              'تحليل/هوكينغ فعّال',
              integrity!.hasCriticalTamper,
              trueNote:  'رُصد ${integrity!.activeSignals.join('، ')} — الخزنة تُعطَّل احترازياً',
              falseNote: 'لا أثر لـ Frida أو Xposed أو مُنقِّح متّصل',
              trueIsWarning: true,
            ),
            StatusBoolRow(
              'بناء قابل للتنقيح (Debuggable)',
              integrity!.isDebuggable,
              trueNote:  'هذه نسخة تطوير — لا تستخدمها لبياناتك الحقيقية',
              falseNote: 'نسخة إصدار غير قابلة للتنقيح',
              trueIsWarning: true,
            ),
            StatusBoolRow(
              'تصحيح USB (ADB) مفعّل',
              integrity!.isAdbEnabled,
              trueNote:  'ADB يوسّع سطح الهجوم — عطّله إن لم تحتجه',
              falseNote: 'ADB غير مفعّل',
              trueIsWarning: true,
            ),
            StatusBoolRow(
              'مصدر تثبيت موثوق',
              integrity!.installerTrusted,
              trueNote:  'مُثبَّت من متجر موثوق',
              falseNote: 'مصدر غير معروف — تأكّد أنك حمّلته من مكان موثوق',
              trueIsWarning: false,
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة كاشف الشذوذ — المرحلة 5
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AnomalyCard extends StatelessWidget {
  final double score;
  final int    sampleCount;
  const _AnomalyCard({required this.score, required this.sampleCount});

  static const _kMinSamples = 5;

  @override
  Widget build(BuildContext context) {
    final ready       = sampleCount >= _kMinSamples;
    final pct         = (score * 100).round();
    final Color color;
    final String statusLabel;

    if (!ready) {
      color       = AppColors.onSurfaceVariant;
      statusLabel = 'جاري بناء خط الأساس';
    } else if (score < 0.30) {
      color       = AppColors.activeMint;
      statusLabel = 'مألوف';
    } else if (score < 0.75) {
      color       = const Color(0xFFFF9500);
      statusLabel = 'شبه مألوف';
    } else {
      color       = AppColors.alertRed;
      statusLabel = 'شذوذ مرصود';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon:      Icons.auto_graph_rounded,
            title:     'كاشف الشذوذ',
            iconColor: color,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // مقياس دائري مبسّط
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value:           ready ? score : null,
                      backgroundColor: AppColors.containerHigh,
                      valueColor:      AlwaysStoppedAnimation<Color>(color),
                      strokeWidth:     5,
                    ),
                    if (ready)
                      Text(
                        '$pct%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      color,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        color:      color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ready
                          ? 'بناءً على $sampleCount ملاحظة — '
                            '${score > 0.75 ? 'نمط المؤشرات يختلف عن المعتاد.' : 'النمط يتوافق مع سلوكك المعتاد.'}'
                          : 'يحتاج ${_kMinSamples - sampleCount} فحص إضافي لبناء خط الأساس.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color:    AppColors.onSurfaceVariant,
                        height:   1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'يقارن مؤشرات الفحص الحالي بسلوكك المعتاد. '
            'درجة مرتفعة تعني تغيّراً ملحوظاً، لا تهديداً مؤكّداً.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color:    AppColors.onSurfaceVariant,
              height:   1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ملاحظة الصدق
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _HonestNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'هذه المؤشرات تُقلّل الخطر وتساعدك تتخذ قرارات أفضل — '
              'لا تضمن حماية مطلقة. الأمان الحقيقي يتطلب طبقات متعددة '
              'ومراجعة مستمرة.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


