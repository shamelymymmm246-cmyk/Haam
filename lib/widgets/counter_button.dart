import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

class CounterButton extends StatelessWidget {
  final IconData icon;
  final Color? backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double size;

  const CounterButton({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor = AppColors.onSurface,
    this.onPressed,
    this.isPrimary = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? (backgroundColor ?? AppColors.safeBlue)
              : (backgroundColor ?? AppColors.glassFill),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}
