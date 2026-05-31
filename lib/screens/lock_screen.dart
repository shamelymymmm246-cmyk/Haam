import 'package:flutter/material.dart';
import 'package:haam_counter/screens/counter_screen.dart';
import 'package:haam_counter/services/auth_service.dart';
import 'package:haam_counter/theme/app_colors.dart';

class LockScreen extends StatefulWidget {
  /// إذا أُعطي [onUnlocked] يُستدعى عند النجاح (مسار الاستئناف من الخلفية).
  /// إذا كان null يُستبدل المسار بـ CounterScreen (مسار بداية التطبيق).
  const LockScreen({super.key, this.onUnlocked});
  final VoidCallback? onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  _State _state = _State.loading;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _state = _State.loading);

    final secured = await AuthService.isDeviceSecured();
    if (!mounted) return;

    if (!secured) {
      setState(() => _state = _State.noLock);
      return;
    }

    final success = await AuthService.authenticate();
    if (!mounted) return;

    if (success) {
      _proceed();
    } else {
      setState(() => _state = _State.failed);
    }
  }

  void _proceed() {
    final callback = widget.onUnlocked;
    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CounterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShieldIcon(),
                const SizedBox(height: 24),
                const Text(
                  'حام',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    switch (_state) {
      case _State.noLock:
        return 'لم يُعيَّن قفل للجهاز — الوصول مفتوح';
      case _State.failed:
        return 'فشل التحقق من الهوية';
      default:
        return 'يُرجى التحقق من هويتك';
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case _State.loading:
        return const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        );

      case _State.failed:
        return Column(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.alertRed, size: 36),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        );

      case _State.noLock:
        return Column(
          children: [
            FilledButton(
              onPressed: _proceed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                minimumSize: const Size(200, 48),
              ),
              child: const Text('دخول'),
            ),
            const SizedBox(height: 16),
            const Text(
              'يُنصح بتفعيل قفل الشاشة في إعدادات الجهاز لتأمين التطبيق',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.outline, fontSize: 12),
            ),
          ],
        );
    }
  }
}

enum _State { loading, failed, noLock }

class _ShieldIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.shield_rounded,
        size: 52,
        color: AppColors.primary,
      ),
    );
  }
}
