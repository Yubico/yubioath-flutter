/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../models.dart';
import '../shortcuts.dart';
import 'action_popup_menu.dart';

class AppListItem extends ConsumerStatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<ActionItem> Function(BuildContext context)? buildPopupActions;
  final Intent? activationIntent;

  const AppListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.buildPopupActions,
    this.activationIntent,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppListItemState();
}

class _AppListItemState extends ConsumerState<AppListItem> {
  final FocusNode _focusNode = FocusNode();
  int _lastTap = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle;
    final buildPopupActions = widget.buildPopupActions;
    final activationIntent = widget.activationIntent;
    final trailing = widget.trailing;
    final hasFeature = ref.watch(featureProvider);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const OpenIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const OpenIntent(),
      },
      child: InkWell(
        focusNode: _focusNode,
        borderRadius: BorderRadius.circular(30),
        onSecondaryTapDown: buildPopupActions == null
            ? null
            : (details) {
                final menuItems = buildPopupActions(context)
                    .where((action) =>
                        action.feature == null || hasFeature(action.feature!))
                    .toList();
                if (menuItems.isNotEmpty) {
                  showPopupMenu(
                    context,
                    details.globalPosition,
                    menuItems,
                  );
                }
              },
        onTap: () {
          if (isDesktop) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastTap < 500) {
              setState(() {
                _lastTap = 0;
              });
              Actions.invoke(context, activationIntent ?? const OpenIntent());
            } else {
              _focusNode.requestFocus();
              setState(() {
                _lastTap = now;
              });
            }
          } else {
            Actions.invoke<OpenIntent>(context, const OpenIntent());
          }
        },
        onLongPress: activationIntent == null
            ? null
            : () {
                Actions.invoke(context, activationIntent);
              },
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            const SizedBox(height: 64),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              leading: widget.leading,
              title: Text(
                widget.title,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                    )
                  : null,
              trailing: trailing == null
                  ? null
                  : Focus(
                      skipTraversal: true,
                      descendantsAreTraversable: false,
                      child: trailing,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
