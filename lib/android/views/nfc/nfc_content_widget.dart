import 'package:flutter/material.dart';

import 'nfc_progress_bar.dart';

class NfcContentWidget extends StatelessWidget {
  final bool inProgress;
  final String? title;
  final String? subtitle;

  const NfcContentWidget(
      {super.key, required this.title, this.subtitle, this.inProgress = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(title ?? 'Missing title',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (subtitle != null)
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 32),
          NfcIconProgressBar(inProgress),
          const SizedBox(height: 24)
        ],
      ),
    );
  }
}
