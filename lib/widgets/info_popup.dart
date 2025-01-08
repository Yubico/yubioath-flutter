import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class InfoPopup extends StatelessWidget {
  final InlineSpan infoMessage;
  const InfoPopup({super.key, required this.infoMessage});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      richMessage: infoMessage,
      child: const Icon(
        Symbols.info,
        size: 18.0,
      ),
    );
  }
}
