import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/providers/locale_provider.dart';
import 'package:haam_counter/screens/lock_screen.dart';
import 'package:haam_counter/screens/splash_screen.dart';
import 'package:haam_counter/theme/app_theme.dart';

class HaamApp extends StatefulWidget {
  const HaamApp({super.key});

  @override
  State<HaamApp> createState() => _HaamAppState();
}

class _HaamAppState extends State<HaamApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  // نمنع دفع شاشة قفل ثانية لو كانت الأولى ما زالت ظاهرة
  bool _lockPushed = false;
  ThemeMode _themeMode = ThemeMode.dark;

  StreamSubscription? _themeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocaleProvider>().loadLocale();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeSub?.cancel();
    super.dispose();
  }

  // إعادة القفل عند عودة التطبيق من الخلفية
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_lockPushed) {
      _lockPushed = true;
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => LockScreen(
            onUnlocked: () {
              _lockPushed = false;
              _navigatorKey.currentState?.pop();
            },
          ),
        ),
      );
    }
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, lp, _) {
        return MaterialApp(
          title: 'حام',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode,
          locale: lp.locale,
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // شاشة التحميل هي الشاشة الأولى — تنتقل إلى الترحيب أو القفل
          home: const SplashScreen(),
        );
      },
    );
  }
}
