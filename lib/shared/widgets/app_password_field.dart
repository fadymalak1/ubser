import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Reusable password field with visibility toggle
class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.labelText = 'كلمة المرور',
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return _AppPasswordFieldStateful(
      controller: controller,
      labelText: labelText,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
    );
  }
}

class _AppPasswordFieldStateful extends StatefulWidget {
  const _AppPasswordFieldStateful({
    this.controller,
    this.labelText,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<_AppPasswordFieldStateful> createState() =>
      _AppPasswordFieldStatefulState();
}

class _AppPasswordFieldStatefulState extends State<_AppPasswordFieldStateful> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}
