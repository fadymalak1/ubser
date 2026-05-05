import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Button that shows loading indicator when [isLoading] is true
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final Widget? icon;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    Widget content = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutlined
                  ? AppTheme.primaryTeal
                  : Colors.white,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      );
    }

    return Container(
      decoration: isLoading || onPressed == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.buttonShadow,
            ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}
