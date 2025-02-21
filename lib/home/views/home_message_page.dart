/*
 * Copyright (C) 2024-2025 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/views/message_page.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import 'key_actions.dart';

class HomeMessagePage extends ConsumerWidget {
  final Widget? graphic;
  final String? header;
  final String? message;
  final String? footnote;
  final bool delayedContent;
  final Widget Function(BuildContext context)? actionButtonBuilder;
  final List<Widget> Function(BuildContext context, bool expanded)?
      actionsBuilder;
  final Widget? fileDropOverlay;
  final Function(File file)? onFileDropped;
  final List<Capability>? capabilities;
  final bool keyActionsBadge;
  final bool centered;

  const HomeMessagePage({
    super.key,
    this.graphic,
    this.header,
    this.message,
    this.footnote,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MessagePage(
      title: l10n.s_home,
      graphic: graphic,
      header: header,
      message: message,
      footnote: footnote,
      keyActionsBuilder: (context) => homeBuildActions(context, null, ref),
      actionButtonBuilder: actionButtonBuilder,
      actionsBuilder: actionsBuilder,
      fileDropOverlay: fileDropOverlay,
      onFileDropped: onFileDropped,
      delayedContent: delayedContent,
      keyActionsBadge: keyActionsBadge,
      capabilities: capabilities,
      centered: centered,
    );
  }
}
