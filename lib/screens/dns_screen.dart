import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/models/dns_status.dart';
import 'package:haam_counter/services/dns_service.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/status_badge.dart';

class DnsScreen extends StatefulWidget {
  const DnsScreen({super.key});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  final _service = DnsService();
  DnsStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final status = await _service.checkStatus();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('تشفير DNS'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة الفحص',
            onPressed: _check,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1520), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: _loading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.safeBlue),
    );
  }

  Widget _buildContent() {
    final s = _status!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHero(status: s)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          _InfoCard(
            title: 'السبب',
            icon: Icons.info_outline_rounded,
            content: s.reason,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          if (s.suggestedAction.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ActionCard(
              action: s.suggestedAction,
              onOpenSettings: () => _service.openPrivateDnsSettings(),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ],

          const SizedBox(height: 16),

          _InfoCard(
            title: 'ما يقلّل الخطر / ما لا يلغيه',
            icon: Icons.shield_outlined,
            content: _honestNote(s),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _honestNote(DnsStatus s) {
    if (s.hasActiveVpn) {
      return 'الـ VPN يُقلّل خطر تجسّس ISP على DNS — لكن مزوّد VPN نفسه يرى '
          'استعلاماتك. اختر مزوّداً موثوقاً ولا تفترض حماية مطلقة.';
    }
    if (s.mode == DnsMode.hostname) {
      return 'DNS مشفّر يُقلّل خطر تجسّس ISP وتلاعب DNS — لكنه لا يُخفي '
          'عناوين IP التي تتصل بها. لمزيد من الخصوصية استخدم VPN أيضاً.';
    }
    return 'تفعيل DNS المشفّر خطوة مهمة — لكن الأمان الكامل يتطلب عدة طبقات. '
        'هذا التطبيق يساعدك ترفع مستوى أمانك، لا يضمنه.';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة الحالة الرئيسية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatusHero extends StatelessWidget {
  final DnsStatus status;
  const _StatusHero({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.isEncrypted ? AppColors.activeMint : AppColors.alertRed;
    final icon  = status.isEncrypted ? Icons.lock_rounded : Icons.lock_open_rounded;

    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.35), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 24)],
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 20),
          StatusBadge(
            isGood: status.isEncrypted,
            label: status.statusLabel,
            fontSize: 15,
          ),
          const SizedBox(height: 12),
          Text(
            status.isEncrypted
                ? 'استعلاماتك للمواقع مُشفَّرة'
                : 'استعلاماتك للمواقع غير مُشفَّرة',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (status.mode == DnsMode.hostname && status.hostname != null) ...[
            const SizedBox(height: 8),
            Text(
              'المزوّد: ${status.hostname}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.safeBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة معلومات (سبب / ملاحظة)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  const _InfoCard({required this.title, required this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurface,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة الإجراء
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ActionCard extends StatelessWidget {
  final String action;
  final VoidCallback onOpenSettings;
  const _ActionCard({required this.action, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.safeBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'الإجراء المقترح',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.safeBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurface,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.safeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                'افتح إعدادات Private DNS',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: onOpenSettings,
            ),
          ),
        ],
      ),
    );
  }
}
