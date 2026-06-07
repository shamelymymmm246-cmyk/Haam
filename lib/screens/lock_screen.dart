import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haam_counter/screens/main_shell.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/services/auth_manager.dart';
import 'package:haam_counter/services/auth_service.dart';
import 'package:haam_counter/theme/app_colors.dart';

class LockScreen extends StatefulWidget {
  /// إذا أُعطي [onUnlocked] يُستدعى عند النجاح (مسار الاستئناف من الخلفية).
  /// إذا كان null يُستبدل المسار بـ MainShell (مسار بداية التطبيق).
  const LockScreen({super.key, this.onUnlocked});
  final VoidCallback? onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  _LsState _state = _LsState.loading;
  final _authManager = AuthManager();
  Timer? _lockoutTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() => _state = _LsState.loading);

    // تحقق من تفعيل القفل البيومتري في الإعدادات
    final biometricEnabled = await AppPrefs.getFlag('biometric_enabled', fallback: true);
    if (!mounted) return;

    if (!biometricEnabled) {
      _proceed();
      return;
    }

    // تحقق من الإغلاق أولاً
    final locked = await _authManager.isLockedOut();
    if (!mounted) return;

    if (locked) {
      _startLockoutTimer();
      return;
    }

    final secured = await AuthService.isDeviceSecured();
    if (!mounted) return;

    if (!secured) {
      setState(() => _state = _LsState.noLock);
      return;
    }

    final result = await AuthService.authenticate();
    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        _proceed();
      case AuthResult.lockedOut:
        _startLockoutTimer();
      case AuthResult.maxAttemptsReached:
        setState(() => _state = _LsState.maxAttempts);
      case AuthResult.noSecurity:
        setState(() => _state = _LsState.noLock);
      case AuthResult.failed:
        setState(() => _state = _LsState.failed);
      case AuthResult.noStrongBiometric:
        setState(() => _state = _LsState.failed);
    }
  }

  void _startLockoutTimer() {
    setState(() => _state = _LsState.lockedOut);
    _updateRemaining();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  Future<void> _updateRemaining() async {
    final until = await _authManager.getLockoutEnd();
    if (until == null) return;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      _lockoutTimer?.cancel();
      await _authManager.reset();
      _authenticate();
      return;
    }
    setState(() => _remaining = remaining);
  }

  void _proceed() {
    final callback = widget.onUnlocked;
    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
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
      case _LsState.noLock:
        return 'لم يُعيَّن قفل للجهاز — الوصول مفتوح';
      case _LsState.failed:
        return 'فشل التحقق من الهوية';
      case _LsState.lockedOut:
        final r = _remaining;
        if (r == null) return 'التطبيق مقفل مؤقتاً';
        final m = r.inMinutes;
        final s = r.inSeconds % 60;
        return 'مقفل مؤقتاً — حاول بعد ${m}د ${s}ث';
      case _LsState.maxAttempts:
        return 'تم تجاوز الحد الأقصى للمحاولات';
      default:
        return 'يُرجى التحقق من هويتك';
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case _LsState.loading:
        return const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        );

      case _LsState.failed:
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

      case _LsState.lockedOut:
        return Column(
          children: [
            const Icon(Icons.timer_off_rounded, color: AppColors.alertRed, size: 48),
            const SizedBox(height: 20),
            const Text(
              'تم قفل التطبيق مؤقتاً لتكرار المحاولات الفاشلة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        );

      case _LsState.maxAttempts:
        return Column(
          children: [
            const Icon(Icons.gpp_bad_rounded, color: AppColors.alertRed, size: 48),
            const SizedBox(height: 20),
            const Text(
              'تم تجاوز 10 محاولات فاشلة — يجب إعادة ضبط التطبيق',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        );

      case _LsState.noLock:
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

enum _LsState { loading, failed, noLock, lockedOut, maxAttempts }

class _ShieldIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.15),
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
