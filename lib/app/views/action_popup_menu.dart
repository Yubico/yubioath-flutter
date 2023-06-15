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

import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';

Future showPopupMenu(BuildContext context, Offset globalPosition,
        List<ActionItem> actions) =>
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        0,
      ),
      items: actions.map((e) => _buildMenuItem(context, e)).toList(),
    );

PopupMenuItem _buildMenuItem(BuildContext context, ActionItem actionItem) {
  final intent = actionItem.intent;
  final enabled = intent != null;
  final shortcut = actionItem.shortcut;
  return PopupMenuItem(
    enabled: enabled,
    onTap: enabled
        ? () {
            // Wait for popup menu to close before running action.
            Timer.run(() {
              Actions.invoke(context, intent);
            });
          }
        : null,
    child: ListTile(
      key: actionItem.key,
      enabled: enabled,
      dense: true,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      title: Text(actionItem.title),
      leading: actionItem.icon,
      trailing: shortcut != null
          ? Opacity(
              opacity: 0.5,
              child: Text(shortcut, textScaleFactor: 0.7),
            )
          : null,
    ),
  );
}
