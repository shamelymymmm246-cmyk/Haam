import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/ldf_status.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/screens/dns_screen.dart';
import 'package:haam_counter/screens/security_overview_screen.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/services/ldf_service.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/ios_toggle.dart';
import 'package:haam_counter/widgets/score_ring.dart';
import 'package:haam_counter/widgets/status_pill.dart';

/// لوحة التحكّم الرئيسية — درجة الأمان + بطاقات الميزات + النشاط الأخير.
/// مطابقة لتصميم haam_dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _ldf = LdfService();
  LdfStatus _ldfStatus = LdfStatus.idle();
  Timer? _poll;

  bool _busyLdf = false;

  @override
  void initState() {
    super.initState();
    _refreshLdf();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refreshLdf());
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoLdfCheck());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _autoLdfCheck() async {
    final autoLdf = await AppPrefs.getFlag('auto_ldf_on_open_wifi', fallback: false);
    if (!mounted) return;
    if (!autoLdf) return;

    final provider = context.read<SecurityStateProvider>();
    final networkInfo = provider.state.networkInfo;
    if (networkInfo != null && networkInfo.isOpenNetwork && !_ldfStatus.running && !_busyLdf) {
      await _toggleLdf(true);
    }
  }

  Future<void> _refreshLdf() async {
    final s = await _ldf.getStatus();
    if (mounted) setState(() => _ldfStatus = s);
  }

  Future<void> _toggleLdf(bool on) async {
    if (_busyLdf) return;
    setState(() => _busyLdf = true);
    if (on) {
      final ok = await _ldf.start();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يُمنح الإذن — لم يبدأ درع الشبكة'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } else {
      await _ldf.stop();
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _refreshLdf();
    if (mounted) setState(() => _busyLdf = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityStateProvider>(
      builder: (context, provider, _) {
        final score = provider.hasScanned ? provider.securityScore : 0;
        final level = provider.level;
        final scanning = provider.loading;
        final dnsEncrypted = provider.state.isDnsEncrypted;
        final camMicApps = provider.state.cameraMicAppsCount;

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
            // ─── درجة الأمان ─────────────────────────────────────
            Center(
              child: ScoreRing(
                progress: score / 100,
                size: 230,
                gradientColors: _ringColors(level),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scanning && !provider.hasScanned ? '...' : '$score%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: level.color,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            Center(
              child: StatusPill(
                label: scanning
                    ? 'جاري فحص جهازك...'
                    : _statusText(level),
                color: level.color,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // ─── بطاقات الميزات (شبكة 2×2) ───────────────────────
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.gpp_good_rounded,
                    iconColor: AppColors.primary,
                    title: 'درع الشبكة',
                    subtitle: _ldfStatus.running
                        ? 'فلتر DNS المحلي نشط'
                        : 'الفلتر المحلي متوقّف',
                    value: _ldfStatus.running,
                    busy: _busyLdf,
                    onChanged: _toggleLdf,
                    onTap: () => widget.onSwitchTab(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.videocam_rounded,
                    iconColor: AppColors.secondary,
                    title: 'حماية الكاميرا',
                    subtitle: !provider.hasScanned
                        ? 'اضغط لمراجعة أذونات الكاميرا والمايك'
                        : (camMicApps == 0
                            ? 'لا تطبيقات تصل لكاميرتك أو مايكك'
                            : '$camMicApps تطبيقاً يصل لكاميرتك/مايكك — راجعها'),
                    value: provider.hasScanned && camMicApps == 0,
                    showToggle: false,
                    trailingIcon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const SecurityOverviewScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.folder_special_rounded,
                    iconColor: AppColors.tertiary,
                    title: 'خزنة الملفات',
                    subtitle: 'تشفير AES-256 مفعّل',
                    value: true,
                    showToggle: false,
                    onTap: () => widget.onSwitchTab(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: AppColors.primaryFixed,
                    title: 'درع الخصوصية',
                    subtitle: dnsEncrypted
                        ? 'DNS مشفّر — يصعّب تتبّعك'
                        : 'DNS غير مشفّر — اضغط للتفعيل',
                    value: dnsEncrypted,
                    showToggle: false,
                    trailingIcon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DnsScreen()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ─── النشاط الأخير ───────────────────────────────────
            Text(
              'النشاط الأخير',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 14),

            _ActivityCard(provider: provider, ldf: _ldfStatus),

            const SizedBox(height: 14),

            _DevicesCard(
              count: provider.state.activeHostsCount,
              scanning: scanning,
            ),
          ],
        ),

            // ─── Speed Dial ────────────────────────────────────────
            _SpeedDial(
              ldfRunning: _ldfStatus.running,
              ldfBusy: _busyLdf,
              lastUpdated: provider.state.lastUpdated,
              hasScanned: provider.hasScanned,
              onToggleLdf: _toggleLdf,
              onScanNow: () => context.read<SecurityStateProvider>().refresh(),
            ),
          ],
        );
      },
    );
  }

  List<Color> _ringColors(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return const [AppColors.primary, AppColors.secondary];
      case RiskLevel.warning:
        return const [AppColors.primary, Color(0xFFFF9500)];
      case RiskLevel.danger:
        return const [Color(0xFFFF9500), AppColors.alertRed];
    }
  }

  String _statusText(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'جميع الأنظمة تعمل بكفاءة';
      case RiskLevel.warning:
        return 'بعض الإعدادات تحتاج انتباهك';
      case RiskLevel.danger:
        return 'رُصدت مخاطر — راجع لوحة الحماية';
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة ميزة بمفتاح iOS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.onTap,
    this.busy = false,
    this.showToggle = true,
    this.trailingIcon = Icons.lock_rounded,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final bool busy;
  final bool showToggle;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 22,
        borderColor: value
            ? AppColors.secondary.withValues(alpha: 0.35)
            : null,
        glowColor: value
            ? AppColors.secondary.withValues(alpha: 0.15)
            : null,
        glowRadius: 20,
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  if (showToggle)
                    busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : IosToggle(value: value, onChanged: onChanged)
                  else
                    Icon(trailingIcon,
                        color: AppColors.secondary, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// بطاقة سجل الحماية (نشاط حقيقي مشتقّ من الفحص)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.provider, required this.ldf});

  final SecurityStateProvider provider;
  final LdfStatus ldf;

  @override
  Widget build(BuildContext context) {
    final s = provider.state;
    final items = <_Activity>[];

    if (provider.hasScanned) {
      items.add(_Activity(
        icon: Icons.check_circle_rounded,
        color: AppColors.secondary,
        title: 'تم فحص ${s.appsWithDangerousPermsCount} تطبيقاً بأذونات حسّاسة',
        time: _timeAgo(s.lastUpdated),
      ));
    }
    items.add(_Activity(
      icon: s.isDnsEncrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
      color: s.isDnsEncrypted ? AppColors.safeBlue : AppColors.tertiaryContainer,
      title: s.isDnsEncrypted ? 'استعلامات DNS مشفّرة' : 'DNS غير مشفّر — يُنصح بالتفعيل',
      time: _timeAgo(s.lastUpdated),
    ));
    if (ldf.running) {
      items.add(_Activity(
        icon: Icons.block_rounded,
        color: AppColors.alertRed,
        title: 'درع الشبكة حجب ${ldf.blockedQueries} استعلاماً',
        time: 'الآن',
      ));
    }
    // المرحلة 4 — إشارات سلامة الجهاز
    final di = s.deviceIntegrity;
    if (di != null) {
      if (di.hasCriticalTamper) {
        items.add(_Activity(
          icon: Icons.gpp_bad_rounded,
          color: AppColors.alertRed,
          title: 'تحذير: رُصد تلاعب في بيئة التشغيل — الخزنة معلّقة',
          time: 'حرجة',
        ));
      }
      if (s.arpSpoofed) {
        items.add(_Activity(
          icon: Icons.wifi_find_rounded,
          color: AppColors.tertiaryContainer,
          title: 'تحذير: تغيّر MAC الـ Gateway — احتمال ARP Spoofing',
          time: 'انتبه',
        ));
      }
    }

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سجل الحماية',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                provider.hasScanned ? 'مُحدّث' : 'بانتظار الفحص',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(color: Color(0x14FFFFFF), height: 20),
            _ActivityRow(activity: items[i]),
          ],
        ],
      ),
    );
  }
}

class _Activity {
  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String time;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activity.color.withValues(alpha: 0.12),
          ),
          child: Icon(activity.icon, color: activity.color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.time,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.count, required this.scanning});
  final int count;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.containerHighest,
            ),
            child: const Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأجهزة المتصلة بالشبكة',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scanning ? 'جاري المسح...' : 'مُكتشفة بمسح المنافذ المحلي',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            scanning ? '…' : '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Speed Dial — فحص سريع وتحكم سريع
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SpeedDial extends StatefulWidget {
  const _SpeedDial({
    required this.ldfRunning,
    required this.ldfBusy,
    required this.lastUpdated,
    required this.hasScanned,
    required this.onToggleLdf,
    required this.onScanNow,
  });

  final bool ldfRunning;
  final bool ldfBusy;
  final DateTime lastUpdated;
  final bool hasScanned;
  final ValueChanged<bool> onToggleLdf;
  final VoidCallback onScanNow;

  @override
  State<_SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<_SpeedDial> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.375).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastAgo = widget.hasScanned ? _timeAgo(widget.lastUpdated) : '—';

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (_expanded)
          GestureDetector(
            onTap: _toggle,
            child: Container(color: Colors.black26),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأزرار الفرعية
              ..._buildActions(lastAgo),
              const SizedBox(height: 12),
              // الزر الرئيسي
              FloatingActionButton(
                onPressed: _toggle,
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                child: AnimatedBuilder(
                  animation: _rotateAnim,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotateAnim.value * 3.14159,
                    child: const Icon(Icons.sensors_rounded, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(String lastAgo) {
    final items = <Widget>[
      _SpeedDialItem(
        icon: Icons.refresh_rounded,
        label: 'فحص الآن',
        onTap: () {
          widget.onScanNow();
          _toggle();
        },
        animCtrl: _animCtrl,
        scaleAnim: _scaleAnim,
        index: 0,
      ),
      _SpeedDialItem(
        icon: Icons.timer_outlined,
        label: 'آخر فحص: $lastAgo',
        onTap: null,
        animCtrl: _animCtrl,
        scaleAnim: _scaleAnim,
        index: 1,
      ),
      _SpeedDialItem(
        icon: widget.ldfRunning ? Icons.vpn_lock_rounded : Icons.vpn_lock_outlined,
        label: widget.ldfRunning ? 'إيقاف LDF' : 'تشغيل LDF',
        onTap: widget.ldfBusy
            ? null
            : () {
                widget.onToggleLdf(!widget.ldfRunning);
                _toggle();
              },
        animCtrl: _animCtrl,
        scaleAnim: _scaleAnim,
        index: 2,
        accent: widget.ldfRunning ? AppColors.alertRed : AppColors.secondary,
      ),
    ];
    return items;
  }
}

class _SpeedDialItem extends StatelessWidget {
  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.animCtrl,
    required this.scaleAnim,
    required this.index,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AnimationController animCtrl;
  final Animation<double> scaleAnim;
  final int index;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder: (context, _) {
        final delay = index * 0.05;
        final t = ((animCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final opacity = Curves.easeOut.transform(t);
        final scale = scaleAnim.value;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: accent ?? AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onTap == null
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
  if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
  return 'قبل ${d.inDays} يوم';
}
