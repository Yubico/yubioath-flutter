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

import '../../management/models.dart';
import 'app_page.dart';

class MessagePage extends StatelessWidget {
  final String? title;
  final Widget? graphic;
  final String? header;
  final String? message;
  final bool delayedContent;
  final Widget Function(BuildContext context)? keyActionsBuilder;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  final List<Widget> Function(BuildContext context, bool expanded)?
      actionsBuilder;
  final Widget? fileDropOverlay;
  final Function(File file)? onFileDropped;
  final List<Capability>? capabilities;
  final bool keyActionsBadge;
  final bool centered;

  const MessagePage({
    super.key,
    this.title,
    this.graphic,
    this.header,
    this.message,
    this.keyActionsBuilder,
    this.actionButtonBuilder,
    this.actionsBuilder,
    this.fileDropOverlay,
    this.onFileDropped,
    this.delayedContent = false,
    this.keyActionsBadge = false,
    this.capabilities,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) => AppPage(
        title: title,
        capabilities: capabilities,
        centered: centered,
        keyActionsBuilder: keyActionsBuilder,
        keyActionsBadge: keyActionsBadge,
        fileDropOverlay: fileDropOverlay,
        onFileDropped: onFileDropped,
        actionButtonBuilder: actionButtonBuilder,
        actionsBuilder: actionsBuilder,
        delayedContent: delayedContent,
        builder: (context, _) => Padding(
          padding: EdgeInsets.only(
              left: 16.0,
              top: 0.0,
              right: 16.0,
              bottom: centered && actionsBuilder == null ? 96 : 0),
          child: SizedBox(
            width: centered ? 250 : 350,
            child: Column(
              crossAxisAlignment: centered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (graphic != null) ...[
                  graphic!,
                  const SizedBox(height: 16.0)
                ],
                if (header != null)
                  Text(header!,
                      textAlign: centered ? TextAlign.center : TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(message!,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: Theme.of(context).textTheme.titleSmall?.apply(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
