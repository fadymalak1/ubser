import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'app_card.dart';

String _riskLevelAr(String level) {
  switch (level) {
    case 'Low':
      return 'منخفض';
    case 'Medium':
      return 'متوسط';
    case 'High':
      return 'عالي';
    default:
      return level;
  }
}

IconData _riskIcon(String level) {
  switch (level.toLowerCase()) {
    case 'low':
    case 'منخفض':
      return Icons.shield_outlined;
    case 'medium':
    case 'متوسط':
      return Icons.warning_amber_rounded;
    case 'high':
    case 'عالي':
      return Icons.crisis_alert_rounded;
    default:
      return Icons.analytics_outlined;
  }
}

/// Displays risk level with modern color-coded badge card
class RiskLevelCard extends StatelessWidget {
  const RiskLevelCard({
    super.key,
    required this.riskLevel,
    this.title = 'مستوى الخطر الحالي',
  });

  final String riskLevel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.riskColor(riskLevel);
    final lightColor = AppTheme.riskLightColor(riskLevel);
    final gradient = AppTheme.riskGradient(riskLevel);
    final displayText =
        (riskLevel == 'Low' || riskLevel == 'Medium' || riskLevel == 'High')
            ? _riskLevelAr(riskLevel)
            : riskLevel;
    final icon = _riskIcon(riskLevel);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayText,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
