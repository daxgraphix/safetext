import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? counterText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final int maxLength;

  const PinInputField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.counterText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLength = 6,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: true,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: const TextStyle(
        fontFamily: 'Roboto Mono',
        fontWeight: FontWeight.w900,
        fontSize: 24,
        letterSpacing: 8.0,
      ),
      decoration: InputDecoration(
        labelText: labelText?.toUpperCase(),
        hintText: hintText ?? '••••',
        errorText: errorText?.toUpperCase(),
        counterText: counterText?.toUpperCase(),
        hintStyle: TextStyle(color: scheme.outline.withValues(alpha: 0.3)),
        suffixIcon: onSubmitted != null
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: onSubmitted,
              )
            : null,
      ),
    );
  }
}
