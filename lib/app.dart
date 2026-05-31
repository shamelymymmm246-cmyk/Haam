import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:haam_counter/screens/lock_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حام',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // LockScreen هي الشاشة الأولى — تُستبدل بـ CounterScreen بعد نجاح التحقق
      home: const LockScreen(),
    );
  }
}
