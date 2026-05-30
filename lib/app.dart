import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:haam_counter/screens/counter_screen.dart';
import 'package:haam_counter/theme/app_theme.dart';

class HaamApp extends StatelessWidget {
  const HaamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حام',
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
      home: const CounterScreen(),
    );
  }
}
