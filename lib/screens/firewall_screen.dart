import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/ldf_status.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/screens/security_overview_screen.dart';
import 'package:haam_counter/services/ldf_service.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/score_ring.dart';
import 'package:haam_counter/widgets/status_pill.dart';

/// شاشة الحماية — درجة الأمان، الهجمات/المخاطر المحجوبة، إحصائيات.
/// مطابقة لتصميم firewall_threat_shield.
class FirewallScreen extends StatefulWidget {
  const FirewallScreen({super.key});

  @override
  State<FirewallScreen> createState() => _FirewallScreenState();
}

class _FirewallScreenState extends State<FirewallScreen> {
  final _ldf = LdfService();
  LdfStatus _ldfStatus = LdfStatus.idle();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refreshLdf();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refreshLdf());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refreshLdf() async {
    final s = await _ldf.getStatus();
    if (mounted) setState(() => _ldfStatus = s);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityStateProvider>(
      builder: (context, provider, _) {
        final score = provider.hasScanned ? provider.securityScore : 0;
        final level = provider.level;
        final rules = provider.riskAssessment.triggeredRules;
        final scanning = provider.loading;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حالة جهازك',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                StatusPill(
                  label: scanning ? 'جاري الفحص' : 'درجة الأمان $score%',
                  color: level.color,
                  glass: false,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── بطاقة الدرجة الرئيسية ───────────────────────────
            _ScoreCard(
              score: score,
              level: level,
              scanning: scanning,
              lastScan: provider.state.lastUpdated,
              issues: rules.length,
              onRescan: () => provider.refresh(),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 26),

            // ─── المخاطر المرصودة ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المخاطر المرصودة',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SecurityOverviewScreen()),
                  ),
                  child: Text(
                    'رؤية الكل',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (rules.isEmpty)
              _CleanState(scanning: scanning)
            else
              for (final r in rules) ...[
                _ThreatRow(rule: r),
                const SizedBox(height: 12),
              ],

            const SizedBox(height: 14),

            // ─── إحصائيات الحماية ────────────────────────────────
            _StatsCard(
              blocked: _ldfStatus.blockedQueries,
              total: _ldfStatus.totalQueries,
              running: _ldfStatus.running,
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          ],
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.level,
    required this.scanning,
    required this.lastScan,
    required this.issues,
    required this.onRescan,
  });

  final int score;
  final RiskLevel level;
  final bool scanning;
  final DateTime lastScan;
  final int issues;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final title = level == RiskLevel.safe
        ? 'وضعك الأمني جيد'
        : level == RiskLevel.warning
            ? 'النظام يحتاج انتباهك'
            : 'رُصدت مخاطر تستحق المعالجة';

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          ScoreRing(
            progress: score / 100,
            size: 190,
            strokeWidth: 9,
            gradientColors: level == RiskLevel.safe
                ? const [AppColors.secondary]
                : [level.color],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(level.icon, color: level.color, size: 40),
                const SizedBox(height: 4),
                Text(
                  scanning ? '…' : '$score',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'درع الحماية يحلّل شبكتك وأذونات التطبيقات وسلامة الجهاز محلياً.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniBox(
                  label: 'آخر فحص',
                  value: scanning ? 'الآن' : _timeAgo(lastScan),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniBox(
                  label: 'مشاكل مرصودة',
                  value: '$issues',
                  valueColor: issues == 0 ? AppColors.secondary : AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: scanning ? null : onRescan,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.glassBorder),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(scanning ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                  size: 18),
              label: Text(
                scanning ? 'جاري الفحص...' : 'إعادة الفحص الآن',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  const _MiniBox({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatRow extends StatelessWidget {
  const _ThreatRow({required this.rule});
  final RuleResult rule;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.gpp_bad_rounded,
                color: AppColors.alertRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rule.suggestedAction.isEmpty ? rule.id : rule.suggestedAction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'تحذير',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanState extends StatelessWidget {
  const _CleanState({required this.scanning});
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Icon(
            scanning ? Icons.hourglass_top_rounded : Icons.verified_user_rounded,
            color: scanning ? AppColors.onSurfaceVariant : AppColors.secondary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            scanning ? 'جاري تحليل جهازك...' : 'لا توجد تهديدات — جهازك نظيف',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scanning
                ? 'يُفحص الآن: الشبكة، أذونات التطبيقات، سلامة الجهاز.'
                : 'لم يرصد محرك القواعد أي مخاطر في الفحص الأخير.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.blocked,
    required this.total,
    required this.running,
  });
  final int blocked;
  final int total;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final allowed = (total - blocked).clamp(0, total);
    final pct = total == 0 ? 0 : (blocked / total * 100).round();
    // نِسَب حقيقية: عرض كل جزء يساوي نصيبه من إجمالي الاستعلامات المقيس فعلياً.
    final blockedFlex = blocked;
    final allowedFlex = allowed;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نشاط الحماية',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            running
                ? (total == 0
                    ? 'درع الشبكة يعمل — لم تُسجَّل استعلامات بعد'
                    : 'حُجب $blocked من أصل $total استعلاماً منذ تشغيل درع الشبكة')
                : 'شغّل درع الشبكة لبدء حجب النطاقات الضارة',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          // شريط نِسبة حقيقية: محجوب مقابل مسموح (لا بيانات وهمية).
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: (total == 0)
                  ? Container(color: AppColors.primary.withValues(alpha: 0.12))
                  : Row(
                      children: [
                        if (blockedFlex > 0)
                          Expanded(
                            flex: blockedFlex,
                            child: Container(
                                color: AppColors.alertRed.withValues(alpha: 0.65)),
                          ),
                        if (allowedFlex > 0)
                          Expanded(
                            flex: allowedFlex,
                            child: Container(
                                color: AppColors.primary.withValues(alpha: 0.22)),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                    label: 'محجوبة', value: '$blocked', color: AppColors.alertRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                    label: 'إجمالي الاستعلامات',
                    value: '$total',
                    color: AppColors.onSurface),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                    label: 'نسبة الحجب',
                    value: '$pct%',
                    color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'منذ لحظات';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
  if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
  return 'منذ ${d.inDays} يوم';
}
