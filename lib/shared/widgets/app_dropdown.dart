import 'package:flutter/material.dart';

/// Reusable dropdown form field
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.prefixIcon,
    this.validator,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? labelText;
  final Widget? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
