import 'package:flutter/material.dart';
import 'input_field.dart';

// Custom rounded password field component
class PasswordField extends StatefulWidget {
  final String? label;
  final String hint;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;

  const PasswordField({
    super.key,
    this.validator,
    this.label,
    this.hint = 'Password',
    this.controller,
    this.fillColor,
    this.textColor,
    this.labelColor,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return InputField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      fillColor: widget.fillColor,
      textColor: widget.textColor,
      labelColor: widget.labelColor,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey.shade600,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
