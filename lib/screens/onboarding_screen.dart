import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haam_counter/screens/lock_screen.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/theme/app_colors.dart';

/// شرائح ترحيبية تُعرض أول مرة فقط — شرح مبسّط وسريع لمميزات "حام".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.verified_user_rounded,
      color: AppColors.primary,
      title: 'أهلاً بك في حام',
      body: 'درعك الأمني الذي يعمل محلياً على جهازك بالكامل — '
          'بلا خوادم خارجية، ولا تُرسل بياناتك لأي مكان.',
    ),
    _Slide(
      icon: Icons.vpn_lock_rounded,
      color: AppColors.activeMint,
      title: 'حماية الشبكة (فلتر DNS محلي)',
      body: 'يمرّ اتصالك عبر فلتر محلي يحجب الإعلانات والمتتبّعات '
          'والنطاقات الضارة تلقائياً — كل المعالجة على جهازك.',
    ),
    _Slide(
      icon: Icons.dns_rounded,
      color: AppColors.safeBlue,
      title: 'تشفير DNS',
      body: 'افحص حالة DNS المشفّر وفعّله بضغطة، '
          'لتمنع التنصّت على المواقع التي تزورها.',
    ),
    _Slide(
      icon: Icons.shield_rounded,
      color: AppColors.secondary,
      title: 'مؤشرات الأمان',
      body: 'راقب صحة شبكتك، وأذونات التطبيقات الخطرة، '
          'وسلامة الجهاز — كلها في لوحة واحدة.',
    ),
    _Slide(
      icon: Icons.fingerprint_rounded,
      color: AppColors.tertiaryContainer,
      title: 'قفل بصمة آمن',
      body: 'يُقفل التطبيق ببصمتك أو رقمك السري، '
          'ويمنع لقطات الشاشة لحماية محتواه.',
    ),
    _Slide(
      icon: Icons.location_on_rounded,
      color: AppColors.safeBlue,
      title: 'لماذا يحتاج حام إذن الموقع؟',
      body: 'يُستخدم إذن الموقع فقط للكشف عن الشبكات المفتوحة '
          'القريبة منك وتحذيرك منها. لا يُرسَل موقعك لأي خادم، '
          'ولا يُخزَّن — المعالجة بالكامل على جهازك.',
    ),
    _Slide(
      icon: Icons.vpn_key_rounded,
      color: AppColors.activeMint,
      title: 'لماذا يطلب حام إذن VPN؟',
      body: 'يستخدم حام واجهة VPN المحلية في أندرويد لفلترة DNS '
          'محلياً (LDF) — لا يمرر بياناتك لخوادم خارجية ولا يشفر '
          'اتصالك لخادم وسيط. كل الحجب والتشميع يتم على جهازك.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  Future<void> _finish() async {
    await AppPrefs.markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطّي
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'تخطّي',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLast ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withValues(alpha: 0.12),
              border: Border.all(color: slide.color.withValues(alpha: 0.3)),
            ),
            child: Icon(slide.icon, size: 60, color: slide.color),
          )
              .animate(key: ValueKey(slide.title))
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ).animate(key: ValueKey('${slide.title}_t')).fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.onSurfaceVariant,
            ),
          ).animate(key: ValueKey('${slide.title}_b')).fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}
