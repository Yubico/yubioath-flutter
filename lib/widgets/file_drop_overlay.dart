import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FileDropOverlay extends StatelessWidget {
  final Widget? graphic;
  final String? title;
  final String? subtitle;

  const FileDropOverlay({super.key, this.graphic, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withValues(alpha: 0.95),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: const BorderRadius.all(Radius.circular(20.0))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          graphic ??
              Icon(
                Symbols.upload_file,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
          if (title != null) ...[
            const SizedBox(height: 16.0),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 12.0),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            )
          ]
        ],
      ),
    );
  }
}
