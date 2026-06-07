import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

/// مفتاح بنمط iOS Control Center — كما في تصميم Haam.
/// عند التفعيل: المسار نعناعي مع توهّج خفيف، والإبهام أبيض ينزلق.
class IosToggle extends StatelessWidget {
  const IosToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.secondary,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeColor : AppColors.containerHighest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: value
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.30), blurRadius: 15)]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
