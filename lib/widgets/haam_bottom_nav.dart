import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/theme/app_colors.dart';

class HaamNavItem {
  const HaamNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// شريط التنقّل السفلي الزجاجي — 5 تبويبات مطابقة لتصميم Haam.
class HaamBottomNav extends StatelessWidget {
  const HaamBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <HaamNavItem>[
    HaamNavItem(icon: Icons.dashboard_rounded, label: 'الرئيسية'),
    HaamNavItem(icon: Icons.language_rounded, label: 'الشبكة'),
    HaamNavItem(icon: Icons.lock_rounded, label: 'الخزنة'),
    HaamNavItem(icon: Icons.shield_rounded, label: 'الحماية'),
    HaamNavItem(icon: Icons.school_rounded, label: 'الأكاديمية'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset, top: 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HaamNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.secondary : AppColors.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
