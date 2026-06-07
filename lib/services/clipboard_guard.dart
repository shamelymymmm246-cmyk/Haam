import 'dart:async';

import 'package:flutter/services.dart';

/// حماية الحافظة (Clipboard) — تمنع نسخ البيانات الحسّاسة وتمسح الحافظة
/// تلقائياً بعد فترة قصيرة.
///
/// المرحلة 4 — طبقة 4-هـ.5:
/// - امسح أي نسخ تلقائي بعد المهلة
/// - وفّر أداة لمسح الحافظة يدوياً
class ClipboardGuard {
  static Timer? _clearTimer;

  /// امسح الحافظة فوراً.
  static Future<void> clear() async {
    _clearTimer?.cancel();
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// انسخ نصاً وامسح الحافظة بعد المهلة المُعطاة (افتراضي 30 ثانية).
  static Future<void> copyWithAutoClear(String text,
      {Duration timeout = const Duration(seconds: 30)}) async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer = Timer(timeout, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  /// امسح الحافظة بعد تأخير (يُستدعى عند فقدان التركيز).
  static void scheduleClear({Duration delay = const Duration(seconds: 5)}) {
    _clearTimer?.cancel();
    _clearTimer = Timer(delay, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  /// ألغِ المسح المجدول (عند العودة للتطبيق).
  static void cancelScheduledClear() {
    _clearTimer?.cancel();
  }
}
