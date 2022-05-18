import 'package:flutter/material.dart';

import 'app_page.dart';

class MessagePage extends StatelessWidget {
  final Widget? title;
  final String header;
  final String message;
  final Widget? floatingActionButton;

  const MessagePage({
    super.key,
    this.title,
    required this.header,
    required this.message,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) => AppPage(
        title: title,
        centered: true,
        floatingActionButton: floatingActionButton,
        child: Column(
          children: [
            Text(header, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12.0),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
}
