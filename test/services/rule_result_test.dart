import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/rule_result.dart';
import 'package:haam_counter/theme/app_colors.dart';

void main() {
  group('RiskLevel', () {
    test('safe has correct label and color', () {
      expect(RiskLevel.safe.label, 'آمن');
      expect(RiskLevel.safe.color, AppColors.activeMint);
    });

    test('warning has correct label and color', () {
      expect(RiskLevel.warning.label, 'انتبه');
      expect(RiskLevel.warning.color, const Color(0xFFFF9500));
    });

    test('danger has correct label and color', () {
      expect(RiskLevel.danger.label, 'خطر');
      expect(RiskLevel.danger.color, AppColors.alertRed);
    });

    test('safe has shield icon', () {
      expect(RiskLevel.safe.icon, Icons.shield_rounded);
    });

    test('warning has warning icon', () {
      expect(RiskLevel.warning.icon, Icons.warning_amber_rounded);
    });

    test('danger has bad icon', () {
      expect(RiskLevel.danger.icon, Icons.gpp_bad_rounded);
    });
  });

  group('RuleResult', () {
    test('stores all fields correctly', () {
      final result = RuleResult(
        id: 'R1',
        reason: 'شبكة مفتوحة',
        suggestedAction: 'فعّل VPN',
        riskWeight: 35,
      );

      expect(result.id, 'R1');
      expect(result.reason, 'شبكة مفتوحة');
      expect(result.suggestedAction, 'فعّل VPN');
      expect(result.riskWeight, 35);
    });
  });

  group('RiskAssessment', () {
    test('stores totalRisk and level correctly', () {
      final assessment = RiskAssessment(
        totalRisk: 55,
        level: RiskLevel.danger,
        triggeredRules: [
          RuleResult(id: 'R1', reason: 'test', suggestedAction: 'test', riskWeight: 35),
        ],
      );

      expect(assessment.totalRisk, 55);
      expect(assessment.level, RiskLevel.danger);
      expect(assessment.triggeredRules.length, 1);
    });

    test('empty factory creates safe state', () {
      final empty = RiskAssessment.empty();
      expect(empty.totalRisk, 0);
      expect(empty.level, RiskLevel.safe);
      expect(empty.triggeredRules, isEmpty);
    });
  });
}
