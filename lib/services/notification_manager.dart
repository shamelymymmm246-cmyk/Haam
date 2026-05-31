import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLastNotifStateKey = 'last_notif_state';
const _kSensitivityKey    = 'notif_sensitivity';
const _kEnabledKey        = 'bg_monitoring_enabled';
const _kCooldownMs        = 2 * 3600 * 1000; // 2 ساعات بالمللي ثانية

/// مستوى حساسية التنبيهات — يحدد متى يُصدر الإشعار بحسب درجة الخطر.
enum NotificationSensitivity {
  off(label: 'معطّل', description: 'لا إشعارات خلفية', threshold: 101),
  low(label: 'منخفضة', description: 'خطر فعلي فقط (> 50)', threshold: 51),
  medium(label: 'متوسطة', description: 'تنبيه وخطر (> 30)', threshold: 31),
  high(label: 'عالية', description: 'أي مشكلة (> 20)', threshold: 21);

  final String label;
  final String description;
  final int threshold;
  const NotificationSensitivity({
    required this.label,
    required this.description,
    required this.threshold,
  });
}

class NotificationManager {
  static const _channelId   = 'haam_security';
  static const _channelName = 'تنبيهات الأمان';
  static const _channelDesc = 'إشعار عند رصد تهديد أمني';

  static final _plugin  = FlutterLocalNotificationsPlugin();
  static final _storage = const FlutterSecureStorage();
  static bool _initialized = false;

  /// يجب استدعاؤه مرة واحدة في main() وفي callbackDispatcher().
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  static Future<NotificationSensitivity> getSensitivity() async {
    final stored = await _storage.read(key: _kSensitivityKey);
    if (stored == null) return NotificationSensitivity.medium;
    return NotificationSensitivity.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => NotificationSensitivity.medium,
    );
  }

  static Future<void> setSensitivity(NotificationSensitivity s) async {
    await _storage.write(key: _kSensitivityKey, value: s.name);
  }

  static Future<bool> isBackgroundEnabled() async {
    final stored = await _storage.read(key: _kEnabledKey);
    return stored != 'false'; // مفعّل بالافتراضي
  }

  static Future<void> setBackgroundEnabled(bool enabled) async {
    await _storage.write(key: _kEnabledKey, value: enabled.toString());
  }

  /// يُصدر إشعاراً إذا:
  ///   1) المراقبة الخلفية مفعّلة
  ///   2) درجة الخطر ≥ عتبة الحساسية المختارة
  ///   3) لم يُصدر نفس مجموعة التنبيهات خلال نافذة التهدئة (2 ساعة)
  ///
  /// يُعيد true إذا صدر الإشعار فعلاً.
  static Future<bool> maybeNotify({
    required int riskScore,
    required List<String> triggeredRuleIds,
    required String reasonSummary,
    required String actionSummary,
  }) async {
    if (!(await isBackgroundEnabled())) return false;
    final sensitivity = await getSensitivity();
    if (riskScore < sensitivity.threshold) return false;

    // Dedup — نفس مجموعة القواعد المُرتّبة هي "نفس التنبيه"
    final sorted    = [...triggeredRuleIds]..sort();
    final stateHash = sorted.join(',');

    final stored = await _storage.read(key: _kLastNotifStateKey);
    if (stored != null) {
      try {
        final map      = jsonDecode(stored) as Map<String, dynamic>;
        final lastHash = map['hash'] as String? ?? '';
        final lastTs   = map['ts']   as int?    ?? 0;
        final elapsed  = DateTime.now().millisecondsSinceEpoch - lastTs;
        if (lastHash == stateHash && elapsed < _kCooldownMs) return false;
      } catch (_) {}
    }

    // سجّل الحالة الحالية
    await _storage.write(
      key: _kLastNotifStateKey,
      value: jsonEncode({
        'hash': stateHash,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    final isHigh = riskScore > 50;
    await _plugin.show(
      1, // معرّف ثابت — يُحدَّث بدل إضافة إشعارات متراكمة
      isHigh ? 'تحذير أمني — حام' : 'تنبيه أمني — حام',
      reasonSummary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: isHigh ? Importance.high : Importance.defaultImportance,
          priority:   isHigh ? Priority.high   : Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            '$reasonSummary\n\nالإجراء المقترح: $actionSummary',
            summaryText: 'درجة الخطر: $riskScore/100',
          ),
          groupKey: 'haam_security_group',
          ticker:   'تنبيه أمني من حام',
        ),
      ),
    );
    return true;
  }
}
