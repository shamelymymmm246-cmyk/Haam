import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/counter_model.dart';
import 'package:haam_counter/providers/counter_provider.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'glass_card.dart';

class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CounterProvider>();
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _ModeOption(
            icon: Icons.shield_rounded,
            label: 'محمي',
            isSelected: provider.mode == CounterMode.protected,
            color: AppColors.activeMint,
            onTap: () => provider.switchMode(CounterMode.protected),
          ),
          _ModeOption(
            icon: Icons.bug_report_rounded,
            label: 'ثغرات',
            isSelected: provider.mode == CounterMode.threats,
            color: AppColors.alertRed,
            onTap: () => provider.switchMode(CounterMode.threats),
          ),
          _ModeOption(
            icon: Icons.search_rounded,
            label: 'فحص',
            isSelected: provider.mode == CounterMode.scan,
            color: AppColors.safeBlue,
            onTap: () => provider.switchMode(CounterMode.scan),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.onSurfaceVariant, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
