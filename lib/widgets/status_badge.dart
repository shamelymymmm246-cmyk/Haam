import 'package:flutter/material.dart';
import 'package:haam_counter/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isGood;
  final String label;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.isGood,
    required this.label,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppColors.activeMint : AppColors.alertRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
