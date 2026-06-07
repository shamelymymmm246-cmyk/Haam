import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/theme/app_colors.dart';

/// شريط علوي زجاجي ثابت — صورة/شعار + العنوان "حام" + جرس الإشعارات.
/// شفّاف مع ضباب خلفي وحدّ سفلي رفيع كما في التصميم.
class HaamTopBar extends StatelessWidget {
  const HaamTopBar({
    super.key,
    this.title = 'حام',
    this.onNotifications,
    this.onProfile,
  });

  final String title;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(top: topInset, left: 20, right: 20),
          height: barHeight + topInset,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.80),
            border: const Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.containerHighest,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/bunyan_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNotifications,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'الإشعارات',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
