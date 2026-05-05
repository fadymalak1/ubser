import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Modern page header with title, optional subtitle and accent decoration
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.centerAlign = false,
    this.showAccent = false,
  });

  final String title;
  final String? subtitle;
  final bool centerAlign;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final textAlign = centerAlign ? TextAlign.center : TextAlign.start;
    final crossAxis =
        centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        if (showAccent) ...[
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
