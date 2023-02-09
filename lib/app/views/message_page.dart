/*
 * Copyright (C) 2022-2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

import 'app_page.dart';

class MessagePage extends StatelessWidget {
  final Widget? title;
  final Widget? graphic;
  final String? header;
  final String? message;
  final List<Widget> actions;
  final bool delayedContent;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final Widget Function(BuildContext context)? actionButtonBuilder;

  const MessagePage({
    super.key,
    this.title,
    this.graphic,
    this.header,
    this.message,
    this.actions = const [],
    this.keyActionsBuilder,
    this.actionButtonBuilder,
    this.delayedContent = false,
  });

  @override
  Widget build(BuildContext context) => AppPage(
        title: title,
        centered: true,
        actions: actions,
        keyActionsBuilder: keyActionsBuilder,
        actionButtonBuilder: actionButtonBuilder,
        delayedContent: delayedContent,
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
