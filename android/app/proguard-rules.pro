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

## ━━━ المرحلة 4 — طبقة 4-ز (تحصين البناء) ━━━
## الكود الأصلي للأمان: نُبقي الأصناف التي تستدعيها قنوات Flutter بالاسم
-keep class com.haam.security.MainActivity { *; }
-keep class com.haam.security.HaamLdfService { *; }
## نسمح بتشويش بقية الأصناف وإعادة تسميتها (التشويش الكامل عبر R8 + optimize)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

## تجريد استدعاءات android.util.Log في release لمنع تسريب بيانات حساسة
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

## ━━━ طبقة 4-ز.4: منع تسريب بيانات حساسة في السجلات ━━━
## System.out/System.err (تُستخدم أحياناً في مكتبات خارجية)
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}

## ━━━ طبقة 4-أ: إثبات النزاهة ━━━
-keep class com.haam.security.MainActivity$SecureStrings { *; }

## ━━━ المرحلة 4 — طبقة 4-و: المصادقة البيومترية ━━━
-keep class androidx.biometric.** { *; }

## ━━━ منع تحذيرات التحقق من الزمن (R8 وقت التشغيل) ━━━
-dontwarn com.haam.security.MainActivity$SecureStrings
