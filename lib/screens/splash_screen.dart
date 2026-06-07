import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haam_counter/screens/lock_screen.dart';
import 'package:haam_counter/screens/onboarding_screen.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/theme/app_colors.dart';

/// شاشة تحميل سريعة تُعرض عند بدء التطبيق — تُظهر شعار "بنيان"
/// ثم تنتقل إلى شرائح الترحيب (أول مرة) أو شاشة القفل مباشرة.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // مدة قصيرة كافية لعرض الشعار دون إبطاء الإقلاع
    final delay = Future<void>.delayed(const Duration(milliseconds: 1400));
    final seen = await AppPrefs.hasSeenOnboarding();
    await delay;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) =>
            seen ? const LockScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF161B27), AppColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bunyan_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 28),
              const Text(
                'حام',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: 8),
              const Text(
                'حماية محلية كاملة لجهازك',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 44),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
