import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/ldf_status.dart';
import 'package:haam_counter/models/security_state.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/screens/dns_screen.dart';
import 'package:haam_counter/screens/ldf_screen.dart';
import 'package:haam_counter/services/ldf_service.dart';
import 'package:haam_counter/services/net_probe.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/status_pill.dart';

/// شاشة الشبكة — درع الشبكة، عنوان IP، الكمون، تدفق البيانات المشفّر،
/// التهديدات المحجوبة. مطابقة لتصميم network_shield.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final _probe = NetProbe();
  final _ldf = LdfService();

  String? _ip;
  int? _latency;
  bool _measuring = true;
  LdfStatus _ldfStatus = LdfStatus.idle();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _measure();
    _refreshLdf();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshLdf();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _measure() async {
    setState(() => _measuring = true);
    final ip = await _probe.localIPv4();
    final lat = await _probe.measureLatency();
    if (!mounted) return;
    setState(() {
      _ip = ip;
      _latency = lat;
      _measuring = false;
    });
  }

  Future<void> _refreshLdf() async {
    final s = await _ldf.getStatus();
    if (mounted) setState(() => _ldfStatus = s);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityStateProvider>(
      builder: (context, provider, _) {
        final info = provider.state.networkInfo;
        final dnsEncrypted = provider.state.isDnsEncrypted;
        final hasVpn = provider.state.hasActiveVpn;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _HeaderCard(
              ldfRunning: _ldfStatus.running,
              ip: _ip,
              info: info,
              latency: _latency,
              measuring: _measuring,
              onRefresh: () {
                _measure();
                provider.refresh();
              },
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 18),

            _FlowCard(
              dnsEncrypted: dnsEncrypted,
              onTapTunnel: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DnsScreen()),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.block_rounded,
                    iconColor: AppColors.tertiaryContainer,
                    value: '${_ldfStatus.blockedQueries}',
                    label: 'نطاق محجوب',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const LdfScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    icon: Icons.vpn_lock_rounded,
                    iconColor: hasVpn ? AppColors.secondary : AppColors.outline,
                    value: hasVpn ? 'نشط' : 'متوقّف',
                    label: hasVpn ? 'شبكة افتراضية VPN' : 'لا يوجد VPN',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 18),

            _SecureTunnelButton(
              running: _ldfStatus.running,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LdfScreen()),
              ),
            ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
          ],
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.ldfRunning,
    required this.ip,
    required this.info,
    required this.latency,
    required this.measuring,
    required this.onRefresh,
  });

  final bool ldfRunning;
  final String? ip;
  final NetworkInfo? info;
  final int? latency;
  final bool measuring;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    final stability = _stability();

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusPill(
                label: ldfRunning ? 'درع الشبكة نشط' : 'متصل بالشبكة',
                color: AppColors.secondary,
                glass: false,
              ),
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.onSurfaceVariant, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            ip ?? (measuring ? '...' : 'غير متصل'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'الكمون',
                  value: measuring
                      ? '...'
                      : (latency != null ? '$latency ms' : '—'),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniStat(
                  label: 'الاستقرار',
                  value: stability,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    if (info == null) return 'لا توجد معلومات شبكة (فعّل الواي فاي والإذن)';
    final name = info!.ssid ?? 'شبكة محلية';
    return '$name • ${info!.encryptionLabel}';
  }

  String _stability() {
    final sig = info?.signal;
    if (sig == null) return '—';
    final pct = (((sig + 100) / 60) * 100).clamp(0, 100).round();
    return '$pct%';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.dnsEncrypted, required this.onTapTunnel});
  final bool dnsEncrypted;
  final VoidCallback onTapTunnel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'تدفق البيانات الآمن',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.smartphone_rounded, color: Color(0x66C1C6D7), size: 34),
              SizedBox(width: 28),
              Icon(Icons.laptop_mac_rounded, color: AppColors.primary, size: 34),
              SizedBox(width: 28),
              Icon(Icons.dns_rounded, color: Color(0x66C1C6D7), size: 34),
            ],
          ),
          const SizedBox(height: 18),
          _AnimatedPackets(active: dnsEncrypted),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onTapTunnel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.glassFillModal,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.20), blurRadius: 28),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    dnsEncrypted ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                    color: dnsEncrypted ? AppColors.primary : AppColors.tertiaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dnsEncrypted ? 'نظام أسماء النطاقات المشفّر' : 'DNS غير مشفّر',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        dnsEncrypted ? 'Encrypted DNS (DoH)' : 'اضغط للفحص والتفعيل',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'يُفحص كل استعلام محلياً على جهازك لحجب الإعلانات والمتتبّعات '
            'والنطاقات الضارة — بلا خادم خارجي.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPackets extends StatelessWidget {
  const _AnimatedPackets({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const SizedBox(height: 6);
    }
    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.2, end: 1, duration: 700.ms, delay: (i * 200).ms);
        }),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecureTunnelButton extends StatelessWidget {
  const _SecureTunnelButton({required this.running, required this.onTap});
  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 18,
        borderColor: running ? AppColors.secondary.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (running ? AppColors.secondary : AppColors.safeBlue)
                    .withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.vpn_lock_rounded,
                color: running ? AppColors.secondary : AppColors.safeBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حماية الشبكة (فلتر DNS محلي)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    running ? 'يعمل الآن — اضغط للتحكّم' : 'اضغط للتشغيل والتحكّم',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
