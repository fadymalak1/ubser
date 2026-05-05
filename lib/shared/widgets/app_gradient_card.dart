import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Card with a full gradient background, used for hero sections
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.borderRadius,
    this.shadows,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
