import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/models/ldf_status.dart';
import 'package:haam_counter/services/ldf_service.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/ambient_background.dart';
import 'package:haam_counter/widgets/glass_card.dart';

/// شاشة حماية الشبكة — تشغيل/إيقاف فلتر DNS المحلي (LDF) وعرض الإحصائيات الحيّة.
class LdfScreen extends StatefulWidget {
  const LdfScreen({super.key});

  @override
  State<LdfScreen> createState() => _LdfScreenState();
}

class _LdfScreenState extends State<LdfScreen> {
  final _service = LdfService();
  LdfStatus _status = LdfStatus.idle();
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = await _service.getStatus();
    if (mounted) setState(() => _status = s);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);

    if (_status.running) {
      await _service.stop();
    } else {
      final ok = await _service.start();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يُمنح الإذن — لم يبدأ فلتر DNS المحلي'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final on = _status.running;
    final accent = on ? AppColors.activeMint : AppColors.outline;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('حماية الشبكة'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: AmbientBackground(
        variant: AmbientVariant.topGlow,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                _PowerButton(on: on, busy: _busy, accent: accent, onTap: _toggle),
                const SizedBox(height: 20),
                Text(
                  on ? 'الحماية المحلية نشطة' : 'الحماية متوقّفة',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  on
                      ? 'يُفحص كل استعلام DNS محلياً وتُحجب الإعلانات والمتتبّعات'
                      : 'اضغط الزر لتشغيل فلتر الشبكة المحلي على جهازك',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.travel_explore_rounded,
                        color: AppColors.safeBlue,
                        value: '${_status.totalQueries}',
                        label: 'استعلام مفحوص',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.block_rounded,
                        color: AppColors.alertRed,
                        value: '${_status.blockedQueries}',
                        label: 'محجوب',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.on,
    required this.busy,
    required this.accent,
    required this.onTap,
  });
  final bool on;
  final bool busy;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
          boxShadow: on
              ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4)]
              : null,
        ),
        child: Center(
          child: busy
              ? CircularProgressIndicator(color: accent, strokeWidth: 2.5)
              : Icon(
                  Icons.power_settings_new_rounded,
                  size: 64,
                  color: accent,
                ),
        ),
      ),
    ).animate(target: on ? 1 : 0).scaleXY(begin: 1, end: 1.03, duration: 600.ms);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const points = [
      'يعمل بالكامل على جهازك — بلا خادم خارجي ولا تُرسل بياناتك لأي مكان.',
      'يحجب نطاقات الإعلانات والتتبّع والمواقع الضارة المعروفة.',
      'يمرّر بقية اتصالك بشكل طبيعي دون إبطاء أو تسجيل.',
    ];
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.activeMint, size: 18),
              const SizedBox(width: 8),
              Text(
                'كيف تعمل الحماية؟',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.secondary, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
