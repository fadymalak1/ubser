import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Mini stat badge pill with icon, value and label
class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryTeal;
    final bg = backgroundColor ?? AppTheme.primaryPaleColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
