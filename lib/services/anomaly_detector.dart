import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haam_counter/models/security_state.dart';

const _kBaselineKey  = 'anomaly_baseline_v1';
const _kMinSamples   = 5;   // عدد الملاحظات الأدنى قبل إعطاء درجة فعلية
const _kFeatureCount = 6;

/// كاشف شذوذ إحصائي خفيف باستخدام خوارزمية Welford للإحصاء المتحرّك.
///
/// يبني خط أساس "طبيعي" من الملاحظات الأولى (activeHostsCount,
/// appsWithDangerousPermsCount, isOpenNetwork, isDnsEncrypted, hasActiveVpn,
/// signal) ثم يُخرج درجة شذوذ 0.0–1.0 لكل ملاحظة جديدة.
///
/// يُدمج كإشارة إضافية في محرك القواعد (R6)، لا بديلاً عنه.
class AnomalyDetector {
  final FlutterSecureStorage _storage;

  List<double> _means = List.filled(_kFeatureCount, 0.0);
  List<double> _m2s   = List.filled(_kFeatureCount, 0.0);
  int _count = 0;

  AnomalyDetector({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  int  get sampleCount => _count;
  bool get hasBaseline => _count >= _kMinSamples;

  // ─── تحميل خط الأساس المخزّن ─────────────────────────────
  Future<void> loadBaseline() async {
    try {
      final raw = await _storage.read(key: _kBaselineKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _count = (data['count'] as num).toInt();
      _means = (data['means'] as List).map((e) => (e as num).toDouble()).toList();
      _m2s   = (data['m2s']   as List).map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      _reset();
    }
  }

  // ─── راقب حالة جديدة، حدّث خط الأساس، وأعد درجة الشذوذ ──
  Future<double> observe(SecurityState state) async {
    final features = _toFeatures(state);
    final score    = _computeScore(features);
    _welfordUpdate(features);
    await _persist();
    return score;
  }

  // ─── متجه المؤشرات (6 أبعاد) ──────────────────────────────
  List<double> _toFeatures(SecurityState state) => [
    state.activeHostsCount.toDouble(),
    state.appsWithDangerousPermsCount.toDouble(),
    state.networkInfo?.isOpenNetwork == true ? 1.0 : 0.0,
    state.isDnsEncrypted ? 0.0 : 1.0,   // مقلوب: 1 = أسوأ
    state.hasActiveVpn   ? 0.0 : 1.0,   // مقلوب: 1 = أسوأ
    state.networkInfo?.signal?.toDouble() ?? -70.0,
  ];

  // ─── حساب درجة الشذوذ بناءً على Z-score ────────────────────
  double _computeScore(List<double> features) {
    if (_count < _kMinSamples) return 0.0;

    double maxZ = 0.0;
    for (int i = 0; i < _kFeatureCount; i++) {
      final variance = _count > 1 ? _m2s[i] / (_count - 1) : 0.0;
      final std      = math.sqrt(variance);
      if (std < 0.001) continue;             // ميزة ثابتة — لا معلومة
      final z = (features[i] - _means[i]).abs() / std;
      if (z > maxZ) maxZ = z;
    }

    // تحويل sigmoid: z=2→~0.27، z=3→~0.73، z=4→~0.93
    // عتبة 0.75 تقابل تقريباً z ≥ 3 (انحراف معياري ثالث)
    return 1.0 / (1.0 + math.exp(-(maxZ - 2.5)));
  }

  // ─── تحديث الإحصاءات بخوارزمية Welford (مستقرة عددياً) ───
  void _welfordUpdate(List<double> features) {
    _count++;
    for (int i = 0; i < _kFeatureCount; i++) {
      final delta  = features[i] - _means[i];
      _means[i]   += delta / _count;
      final delta2 = features[i] - _means[i];
      _m2s[i]     += delta * delta2;
    }
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _kBaselineKey,
      value: jsonEncode({'count': _count, 'means': _means, 'm2s': _m2s}),
    );
  }

  void _reset() {
    _count = 0;
    _means = List.filled(_kFeatureCount, 0.0);
    _m2s   = List.filled(_kFeatureCount, 0.0);
  }
}
