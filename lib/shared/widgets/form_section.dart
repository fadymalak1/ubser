import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Wraps form content with consistent padding and scroll behavior
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: child,
    );
  }
}
