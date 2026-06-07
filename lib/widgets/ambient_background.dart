import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

enum AmbientVariant {
  standard,
  topGlow,
  heavy,
}

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.leaks = true,
    this.variant = AmbientVariant.standard,
  });

  final Widget child;
  final bool leaks;
  final AmbientVariant variant;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: -1,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll(double delta) {
    _scrollController.value =
        (_scrollController.value + delta * 0.001).clamp(-1.0, 1.0);
    setState(() => _scrollOffset = _scrollController.value);
  }

  @override
  Widget build(BuildContext context) {
    final leakOffset = _scrollOffset * 20;

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        _onScroll(notification.scrollDelta ?? 0);
        return false;
      },
      child: Stack(
        children: [
          if (widget.variant == AmbientVariant.topGlow)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D1520), AppColors.background],
                  ),
                ),
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(color: AppColors.background),
            ),
          if (widget.leaks) ...[
            Positioned(
              top: -140 + leakOffset,
              left: -140 - leakOffset * 0.5,
              child: _Leak(
                color: AppColors.primary,
                radius: widget.variant == AmbientVariant.heavy ? 520 : 420,
                opacity: widget.variant == AmbientVariant.heavy ? 0.25 : 0.18,
              ),
            ),
            Positioned(
              bottom: -140 - leakOffset,
              right: -140 + leakOffset * 0.5,
              child: _Leak(
                color: AppColors.secondary,
                radius: widget.variant == AmbientVariant.heavy ? 520 : 420,
                opacity: widget.variant == AmbientVariant.heavy ? 0.25 : 0.18,
              ),
            ),
          ],
          widget.child,
        ],
      ),
    );
  }
}

class _Leak extends StatelessWidget {
  const _Leak({
    required this.color,
    this.radius = 420,
    this.opacity = 0.18,
  });

  final Color color;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
