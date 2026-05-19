import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class PersonalizationMetricField extends StatelessWidget {
  final String label;
  final String hint;
  final String? suffix;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const PersonalizationMetricField({
    super.key,
    required this.label,
    required this.hint,
    this.suffix,
    required this.controller,
    required this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitoraSpacing.md,
          vertical: FitoraSpacing.md,
        ),
      ),
    );
  }
}
