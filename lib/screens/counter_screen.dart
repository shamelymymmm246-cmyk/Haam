import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/providers/counter_provider.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/circular_progress.dart';
import 'package:haam_counter/widgets/counter_display.dart';
import 'package:haam_counter/widgets/counter_button.dart';
import 'package:haam_counter/widgets/security_chip.dart';
import 'package:haam_counter/widgets/mode_switcher.dart';
import 'package:haam_counter/screens/dns_screen.dart';
import 'package:haam_counter/screens/security_overview_screen.dart';
import 'package:haam_counter/screens/settings_screen.dart';

class _DnsShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DnsScreen()),
      ),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.safeBlue.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.dns_rounded,
                color: AppColors.safeBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة DNS المشفّر',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'اضغط للفحص والتفعيل',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityOverviewShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SecurityOverviewScreen()),
      ),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.activeMint.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppColors.activeMint,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مؤشرات الأمان',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'شبكة · تطبيقات · سلامة الجهاز',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('حام'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Consumer<CounterProvider>(
                    builder: (context, provider, _) {
                      return CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),

                          // مبدل الأوضاع
                          SliverToBoxAdapter(
                            child: ModeSwitcher(),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          // البطاقة الرئيسية
                          SliverToBoxAdapter(
                            child: GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  CircularProgress(
                                    progress: provider.progress,
                                    accentColor: provider.accentColor,
                                    size: isWide ? 220 : 180,
                                  ),
                                  const SizedBox(height: 32),
                                  CounterDisplay(
                                    count: provider.count,
                                    label: provider.label,
                                    accentColor: provider.accentColor,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 32)),

                          // أزرار + / −
                          SliverToBoxAdapter(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CounterButton(
                                  icon: Icons.remove_rounded,
                                  onPressed: provider.decrement,
                                ),
                                const SizedBox(width: 28),
                                CounterButton(
                                  icon: Icons.add_rounded,
                                  isPrimary: true,
                                  iconColor: Colors.white,
                                  onPressed: provider.increment,
                                ),
                              ],
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 20)),

                          // زر إعادة التعيين
                          SliverToBoxAdapter(
                            child: Center(
                              child: CounterButton(
                                icon: Icons.refresh_rounded,
                                iconColor: AppColors.onSurfaceVariant,
                                size: 48,
                                onPressed: provider.reset,
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 40)),

                          // Status Footer
                          SliverToBoxAdapter(
                            child: GlassCard(
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  SecurityChip(
                                    label: 'نشط',
                                    dotColor: provider.accentColor,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'آخر تحديث: الآن',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 16)),

                          // بطاقة DNS مشفّر — المرحلة 1
                          SliverToBoxAdapter(
                            child: _DnsShortcut(),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),

                          // مؤشرات الأمان — المرحلة 2
                          SliverToBoxAdapter(
                            child: _SecurityOverviewShortcut(),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
