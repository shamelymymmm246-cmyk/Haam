import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/providers/locale_provider.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/services/background_service.dart';
import 'package:haam_counter/services/notification_manager.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/ambient_background.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/shared/card_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bgEnabled = true;
  NotificationSensitivity _sensitivity = NotificationSensitivity.medium;
  bool _autoLdf = false;
  bool _biometricEnabled = true;
  bool _loading = true;
  String _locale = 'ar';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled     = await NotificationManager.isBackgroundEnabled();
    final sensitivity = await NotificationManager.getSensitivity();
    final autoLdf     = await AppPrefs.getFlag('auto_ldf_on_open_wifi', fallback: false);
    final biometric   = await AppPrefs.getFlag('biometric_enabled', fallback: true);
    if (!mounted) return;
    setState(() {
      _bgEnabled        = enabled;
      _sensitivity      = sensitivity;
      _autoLdf          = autoLdf;
      _biometricEnabled = biometric;
      _loading          = false;
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

  Future<void> _setAutoLdf(bool value) async {
    await AppPrefs.setFlag('auto_ldf_on_open_wifi', value);
    if (!mounted) return;
    setState(() => _autoLdf = value);
  }

  Future<void> _setBiometricEnabled(bool value) async {
    await AppPrefs.setFlag('biometric_enabled', value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  void _setLocale(String code) {
    context.read<LocaleProvider>().setLocale(code);
    setState(() => _locale = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: AmbientBackground(
        variant: AmbientVariant.topGlow,
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
          const SectionHeader(title: 'المراقبة الخلفية')
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
              activeThumbColor: AppColors.safeBlue,
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
          const SectionHeader(title: 'حساسية التنبيهات')
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
                    borderColor: isSelected ? AppColors.safeBlue.withValues(alpha: 0.6) : null,
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

          const SizedBox(height: 24),

          // ─── LDF تلقائي عند WiFi مفتوحة ──────────────────────────
          const SectionHeader(title: 'LDF تلقائي')
              .animate().fadeIn(delay: 220.ms, duration: 300.ms),

          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'تفعيل LDF تلقائياً عند WiFi مفتوحة',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'يُشغّل درع الشبكة (LDF) فوراً عند الاتصال بشبكة بدون تشفير',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              value: _autoLdf,
              activeThumbColor: AppColors.safeBlue,
              onChanged: _setAutoLdf,
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // ─── القفل البيومتري ─────────────────────────────────────
          const SectionHeader(title: 'القفل البيومتري')
              .animate().fadeIn(delay: 260.ms, duration: 300.ms),

          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'تفعيل القفل بالبصمة',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'قفل التطبيق بالبصمة أو PIN عند فتحه أو العودة من الخلفية',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              value: _biometricEnabled,
              activeThumbColor: AppColors.safeBlue,
              onChanged: _setBiometricEnabled,
            ),
          ).animate().fadeIn(delay: 280.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // ─── اللغة ───────────────────────────────────────────────
          const SectionHeader(title: 'اللغة')
              .animate().fadeIn(delay: 300.ms, duration: 300.ms),

          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: AppColors.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لغة التطبيق',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _locale,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.containerHigh,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {
                    if (v != null) _setLocale(v);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 320.ms, duration: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


