import 'package:flutter/material.dart';

class SmallWhiteText extends StatelessWidget {
  final String _text;

  const SmallWhiteText(this._text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    _text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
  );
}
