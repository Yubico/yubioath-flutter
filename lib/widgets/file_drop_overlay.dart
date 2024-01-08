import 'package:flutter/material.dart';

class FileDropOverlay extends StatelessWidget {
  final Widget? graphic;
  final String? title;
  final String? subTitle;

  const FileDropOverlay({super.key, this.graphic, this.title, this.subTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;

    return Positioned.fill(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Color(darkMode ? 0xFF151515 : 0xFFE6E6E6).withOpacity(0.95),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: const BorderRadius.all(Radius.circular(20.0))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            graphic ??
                Icon(
                  Icons.upload_file,
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
            if (subTitle != null) ...[
              const SizedBox(height: 12.0),
              Text(
                subTitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              )
            ]
          ],
        ),
      ),
    ));
  }
}
