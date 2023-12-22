import 'package:flutter/material.dart';

class VisibilityIcon extends StatelessWidget {
  final bool _isObscure;

  const VisibilityIcon(this._isObscure, {super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(_isObscure ? Icons.visibility : Icons.visibility_off);
}
