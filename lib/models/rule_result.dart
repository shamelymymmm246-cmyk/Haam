import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

enum RiskLevel { safe, warning, danger }

extension RiskLevelExt on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:    return 'آمن';
      case RiskLevel.warning: return 'انتبه';
      case RiskLevel.danger:  return 'خطر';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.safe:    return AppColors.activeMint;
      case RiskLevel.warning: return const Color(0xFFFF9500);
      case RiskLevel.danger:  return AppColors.alertRed;
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.safe:    return Icons.shield_rounded;
      case RiskLevel.warning: return Icons.warning_amber_rounded;
      case RiskLevel.danger:  return Icons.gpp_bad_rounded;
    }
  }
}

class RuleResult {
  final String id;
  final String reason;
  final String suggestedAction;
  final int riskWeight;

  const RuleResult({
    required this.id,
    required this.reason,
    required this.suggestedAction,
    required this.riskWeight,
  });
}

class RiskAssessment {
  final int totalRisk;
  final RiskLevel level;
  final List<RuleResult> triggeredRules;

  const RiskAssessment({
    required this.totalRisk,
    required this.level,
    required this.triggeredRules,
  });

  factory RiskAssessment.empty() => const RiskAssessment(
        totalRisk: 0,
        level: RiskLevel.safe,
        triggeredRules: [],
      );
}
