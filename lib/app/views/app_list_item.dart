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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../models.dart';
import '../shortcuts.dart';
import 'action_popup_menu.dart';

class AppListItem<T> extends ConsumerStatefulWidget {
  final T item;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? semanticTitle;
  final Widget? trailing;
  final List<ActionItem> Function(BuildContext context)? buildPopupActions;
  final Intent? tapIntent;
  final Intent? doubleTapIntent;
  final bool selected;

  const AppListItem(
    this.item, {
    super.key,
    this.leading,
    required this.title,
    this.semanticTitle,
    this.subtitle,
    this.trailing,
    this.buildPopupActions,
    this.tapIntent,
    this.doubleTapIntent,
    this.selected = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppListItemState<T>();
}

class _AppListItemState<T> extends ConsumerState<AppListItem> {
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
    final tapIntent = widget.tapIntent;
    final doubleTapIntent = widget.doubleTapIntent;
    final trailing = widget.trailing;
    final hasFeature = ref.watch(featureProvider);

    return Semantics(
      label: widget.semanticTitle ?? widget.title,
      child: ItemShortcuts<T>(
        item: widget.item,
        child: InkWell(
          focusNode: _focusNode,
          borderRadius: BorderRadius.circular(48),
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
            _focusNode.requestFocus();
            if (tapIntent != null) {
              Actions.invoke(context, tapIntent);
            }
            if (isDesktop && doubleTapIntent != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - _lastTap < 500) {
                setState(() {
                  _lastTap = 0;
                });
                Actions.invoke(context, doubleTapIntent);
              } else {
                setState(() {
                  _lastTap = now;
                });
              }
            }
          },
          onLongPress: doubleTapIntent == null
              ? null
              : () {
                  Actions.invoke(context, doubleTapIntent);
                },
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              const SizedBox(height: 64),
              ListTile(
                mouseCursor:
                    widget.tapIntent != null ? SystemMouseCursors.click : null,
                selected: widget.selected,
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
      ),
    );
  }
}
