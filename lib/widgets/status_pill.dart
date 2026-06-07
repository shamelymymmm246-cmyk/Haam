import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';

/// شارة حالة بيضاوية مع نقطة نابضة — كما في تصميم Haam.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.secondary,
    this.glass = true,
  });

  final String label;
  final Color color;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 900.ms)
            .then()
            .fade(begin: 1, end: 0.3, duration: 900.ms),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: glass ? AppColors.onSurfaceVariant : color,
          ),
        ),
      ],
    );

    if (glass) {
      return GlassCard(
        borderRadius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: content,
    );
  }
}
