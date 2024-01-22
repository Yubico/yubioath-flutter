/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'app_page.dart';

class MessagePage extends StatelessWidget {
  final Widget? graphic;
  final String? header;
  final String? message;
  final List<Widget> actions;
  final bool delayedContent;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  final Widget? fileDropOverlay;
  final Function(File file)? onFileDropped;
  final bool keyActionsBadge;

  const MessagePage({
    super.key,
    this.graphic,
    this.header,
    this.message,
    this.actions = const [],
    this.keyActionsBuilder,
    this.actionButtonBuilder,
    this.fileDropOverlay,
    this.onFileDropped,
    this.delayedContent = false,
    this.keyActionsBadge = false,
  });

  @override
  Widget build(BuildContext context) => AppPage(
        centered: true,
        actions: actions,
        keyActionsBuilder: keyActionsBuilder,
        keyActionsBadge: keyActionsBadge,
        fileDropOverlay: fileDropOverlay,
        onFileDropped: onFileDropped,
        actionButtonBuilder: actionButtonBuilder,
        delayedContent: delayedContent,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.only(
              left: 32.0, top: 0.0, right: 32.0, bottom: 96.0),
          child: SizedBox(
            width: 350,
            child: Column(
              children: [
                if (graphic != null) ...[
                  graphic!,
                  const SizedBox(height: 16.0)
                ],
                if (header != null)
                  Text(header!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: 12.0),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.apply(color: Colors.grey)),
                ],
              ],
            ),
          ),
        ),
      );
}
