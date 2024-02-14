/*
 * Copyright (C) 2024 Yubico.
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

import '../../core/state.dart';

class AppContextMenu extends StatelessWidget {
  final List<MenuItemButton> menuChildren;
  final Widget child;
  final List<Key>? dividers;

  const AppContextMenu({
    super.key,
    required this.menuChildren,
    required this.child,
    this.dividers,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      anchorTapClosesMenu: true,
      builder: (context, controller, _) {
        return GestureDetector(
          onSecondaryTapDown: isDesktop
              ? (details) {
                  if (menuChildren.isNotEmpty && !controller.isOpen) {
                    controller.open(position: details.localPosition);
                  }
                }
              : null,
          onLongPressStart: isAndroid
              ? (details) {
                  if (menuChildren.isNotEmpty && !controller.isOpen) {
                    controller.open(position: details.localPosition);
                  }
                }
              : null,
          child: child,
        );
      },
      menuChildren: buildMenuChildren(context, menuChildren, dividers),
    );
  }
}

List<Widget> buildMenuChildren(BuildContext context,
    List<MenuItemButton> menuChildren, List<Key>? dividers) {
  List<Widget> res = [];
  for (var child in menuChildren) {
    if (dividers != null && dividers.contains(child.key)) {
      res.add(const Divider());
    }
    res.add(child);
  }
  return res;
}
