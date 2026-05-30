import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/theme/app_colors.dart';

class CounterDisplay extends StatelessWidget {
  final int count;
  final String label;
  final Color accentColor;

  const CounterDisplay({
    super.key,
    required this.count,
    required this.label,
    this.accentColor = AppColors.safeBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          child: Text(
            count.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
