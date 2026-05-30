import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/theme/app_colors.dart';

class CircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final Color accentColor;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 180,
    this.accentColor = AppColors.safeBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.safeBlue, AppColors.activeMint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AppColors.glassTrack,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'الأمان',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
