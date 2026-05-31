import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/services/background_service.dart';
import 'package:haam_counter/services/notification_manager.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bgEnabled = true;
  NotificationSensitivity _sensitivity = NotificationSensitivity.medium;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled     = await NotificationManager.isBackgroundEnabled();
    final sensitivity = await NotificationManager.getSensitivity();
    if (!mounted) return;
    setState(() {
      _bgEnabled   = enabled;
      _sensitivity = sensitivity;
      _loading     = false;
    });
  }

  Future<void> _setBgEnabled(bool value) async {
    await NotificationManager.setBackgroundEnabled(value);
    if (value) {
      await BackgroundService.registerPeriodicScan();
    } else {
      await BackgroundService.cancelAll();
    }
    if (!mounted) return;
    setState(() => _bgEnabled = value);
  }

  Future<void> _setSensitivity(NotificationSensitivity s) async {
    await NotificationManager.setSensitivity(s);
    if (!mounted) return;
    setState(() => _sensitivity = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.safeBlue))
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── المراقبة الخلفية ─────────────────────────────────
          _SectionHeader(title: 'المراقبة الخلفية')
              .animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'تفعيل المراقبة الخلفية',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'فحص دوري كل 15 دقيقة — قد يتأخر بسبب وضع توفير البطارية',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              value: _bgEnabled,
              activeColor: AppColors.safeBlue,
              onChanged: _setBgEnabled,
            ),
          ).animate().fadeIn(delay: 50.ms, duration: 300.ms),

          const SizedBox(height: 8),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سلوك طبيعي لنظام Android: قد يؤجّل وضع Doze تنفيذ '
                    'الفحص عندما يكون الجهاز خاملاً. هذا لا يُعطّل الميزة '
                    '— يعني فقط أن الفحص قد يتأخر قليلاً.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // ─── حساسية التنبيهات ──────────────────────────────────
          _SectionHeader(title: 'حساسية التنبيهات')
              .animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 4),

          Text(
            'متى يُصدر إشعاراً؟',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 300.ms),

          const SizedBox(height: 12),

          ...NotificationSensitivity.values.map((s) {
            final isSelected = _sensitivity == s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: _bgEnabled ? () => _setSensitivity(s) : null,
                child: AnimatedOpacity(
                  opacity: _bgEnabled ? 1.0 : 0.45,
                  duration: 200.ms,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderColor: isSelected ? AppColors.safeBlue.withOpacity(0.6) : null,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.safeBlue : AppColors.outline,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.safeBlue,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.label,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.safeBlue
                                      : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ─── ملاحظة التهدئة ────────────────────────────────────
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_off_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'نافذة التهدئة: إذا أُصدر إشعار لسبب معيّن، '
                    'لن يُعاد إصداره لنفس السبب خلال ساعتين. '
                    'هذا يمنع الإزعاج المتكرر مع إبقاء التنبيهات المفيدة.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.safeBlue,
        letterSpacing: 0.6,
      ),
    );
  }
}
