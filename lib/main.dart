import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/app.dart';
import 'package:haam_counter/providers/locale_provider.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/services/background_service.dart';
import 'package:haam_counter/services/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // المرحلة 4 — تهيئة الإشعارات والمراقبة الخلفية
  await NotificationManager.initialize();
  await BackgroundService.initialize();
  await BackgroundService.registerPeriodicScan();

  // طلب إذن POST_NOTIFICATIONS على Android 13+ (API 33)
  await Permission.notification.request();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF10131B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SecurityStateProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const HaamApp(),
    ),
  );
}
