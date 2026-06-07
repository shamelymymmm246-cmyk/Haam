import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

/// حلقة درجة الأمان — مسار دائري متدرّج (أزرق → نعناعي) بنهايات مستديرة
/// مطابق لتصميم Haam. يتحرّك تلقائياً عند تغيّر القيمة.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.progress,
    required this.center,
    this.size = 240,
    this.strokeWidth = 14,
    this.gradientColors = const [AppColors.primary, AppColors.secondary],
    this.trackColor = const Color(0x14FFFFFF),
  });

  /// 0.0 – 1.0
  final double progress;
  final Widget center;
  final double size;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  gradientColors: gradientColors,
                  trackColor: trackColor,
                ),
              ),
              center,
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // المسار الخلفي
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress <= 0) return;

    // المسار المتدرّج النشط — يبدأ من الأعلى (-90°)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: gradientColors.length == 1
          ? [gradientColors.first, gradientColors.first]
          : gradientColors,
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final progressPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.gradientColors != gradientColors ||
      old.trackColor != trackColor;
}
