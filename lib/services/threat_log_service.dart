import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/models/threat_log_entry.dart';

/// خدمة تخزين دائري لسجل التهديدات المحجوبة فعلياً بواسطة LDF.
///
/// المرحلة 4 — طبقة 4-د: كل دخول يمثّل نطاقاً حُجب حقيقية (لا أرقام وهمية).
/// السجل محدود بسعة قصوى (200 دخول) لتجنّب تضخّم التخزين.
class ThreatLogService {
  static const _key = 'threat_log_v1';
  static const _maxEntries = 200;

  final FlutterSecureStorage _storage;

  ThreatLogService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<ThreatLogEntry>> getLog() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ThreatLogEntry(
                id: e['id'] as String,
                domain: e['domain'] as String,
                category: ThreatCategory.values[e['cat'] as int? ?? 5],
                timestamp:
                    DateTime.fromMillisecondsSinceEpoch(e['ts'] as int),
                isBlocked: e['blocked'] as bool? ?? true,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(ThreatLogEntry entry) async {
    final log = await getLog();
    log.insert(0, entry);
    if (log.length > _maxEntries) {
      log.removeRange(_maxEntries, log.length);
    }
    await _persist(log);
  }

  Future<void> _persist(List<ThreatLogEntry> log) async {
    final json = log
        .map((e) => {
              'id': e.id,
              'domain': e.domain,
              'cat': e.category.index,
              'ts': e.timestamp.millisecondsSinceEpoch,
              'blocked': e.isBlocked,
            })
        .toList();
    await _storage.write(key: _key, value: jsonEncode(json));
  }

  /// عدد المحجوب اليوم (لمطابقة عدّاد LDF الحقيقي).
  Future<int> todayBlockedCount() async {
    final log = await getLog();
    final today = DateTime.now();
    return log.where((e) =>
        e.isBlocked &&
        e.timestamp.year == today.year &&
        e.timestamp.month == today.month &&
        e.timestamp.day == today.day).length;
  }

  /// إجمالي المحجوب.
  Future<int> totalBlockedCount() async {
    final log = await getLog();
    return log.where((e) => e.isBlocked).length;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
