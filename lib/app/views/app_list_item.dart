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
import 'keys.dart' as keys;

class AppListItem<T> extends ConsumerStatefulWidget {
  final T item;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? semanticTitle;
  final Widget? trailing;
  final List<ActionItem> Function(BuildContext context)? buildPopupActions;
  final Widget Function(BuildContext context)? itemBuilder;
  final Intent? tapIntent;
  final Intent? doubleTapIntent;
  final Color? tileColor;
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
    this.itemBuilder,
    this.tapIntent,
    this.doubleTapIntent,
    this.tileColor,
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final semanticTitle = widget.semanticTitle ?? widget.title;
    final semanticLabel = subtitle == null
        ? semanticTitle
        : '$semanticTitle\n$subtitle';

    return Semantics(
      label: semanticLabel,
      selected: widget.selected ? true : null,
      child: ItemShortcuts<T>(
        item: widget.item,
        child: InkWell(
          focusNode: _focusNode,
          mouseCursor:
              widget.tapIntent != null ? SystemMouseCursors.click : null,
          customBorder: shape,
          onSecondaryTapDown: buildPopupActions == null
              ? null
              : (details) {
                  final menuItems = buildPopupActions(context)
                      .where(
                        (action) =>
                            action.feature == null ||
                            hasFeature(action.feature!),
                      )
                      .toList();
                  if (menuItems.isNotEmpty) {
                    showPopupMenu(context, details.globalPosition, menuItems);
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
          child: widget.itemBuilder != null
              ? widget.itemBuilder!.call(context)
              : SizedBox(
                  height: 64,
                  child: Ink(
                    decoration: ShapeDecoration(
                      shape: shape,
                      color: widget.selected
                          ? colorScheme.secondaryContainer
                          : widget.tileColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          if (widget.leading != null) ...[
                            ExcludeSemantics(child: widget.leading!),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: subtitle == null
                                ? SizedBox(
                                    height: 48,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ExcludeSemantics(
                                        child: Text(
                                          widget.title,
                                          overflow: .fade,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: widget.selected
                                              ? theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSecondaryContainer,
                                                  )
                                              : theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: .center,
                                    crossAxisAlignment: .start,
                                    children: [
                                      ExcludeSemantics(
                                        child: Text(
                                          widget.title,
                                          overflow: .fade,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: widget.selected
                                              ? theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSecondaryContainer,
                                                  )
                                              : theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                      ExcludeSemantics(
                                        child: Text(
                                          subtitle,
                                          overflow: .fade,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: widget.selected
                                                    ? colorScheme
                                                        .onSecondaryContainer
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            Focus(
                              key: keys.appListItemActionKey,
                              skipTraversal: true,
                              descendantsAreTraversable: false,
                              child: trailing,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
