## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
## Kotlin
-dontwarn kotlin.**

## Play Core — يشير إليها Flutter للمكوّنات المؤجّلة (غير مستخدمة في التطبيق) — نتجاهل تحذيراتها
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## flutter_secure_storage — Android Keystore
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## local_auth — Biometric API (المرحلة 6)
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

## workmanager (النسخة 0.9.0 — حزمة dev.fluttercommunity)
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }

## flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

## تجريد استدعاءات android.util.Log في release لمنع تسريب بيانات حساسة
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
