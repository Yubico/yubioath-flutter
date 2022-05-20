import 'package:flutter/material.dart';

import '../models.dart';
import 'app_page.dart';

class MessagePage extends StatelessWidget {
  final Widget? title;
  final Widget? graphic;
  final String? header;
  final String? message;
  final List<MenuAction> actions;

  const MessagePage({
    super.key,
    this.title,
    this.graphic,
    this.header,
    this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => AppPage(
        title: title,
        centered: true,
        actions: actions,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (graphic != null) graphic!,
              if (header != null)
                Text(header!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12.0),
              if (message != null) ...[
                Text(message!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
}
