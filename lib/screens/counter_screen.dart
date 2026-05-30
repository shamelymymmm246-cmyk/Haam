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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
