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
import 'package:material_symbols_icons/symbols.dart';

import '../app/state.dart';
import 'tap_request_dialog.dart';

void showAlertDialog(ref, String title, String message, String description,
        [Function()? onClosed]) =>
    ref.read(withContextProvider)((context) async {
      ref.read(androidDialogProvider).closeDialog();
      Navigator.of(context).popUntil((route) {
        return route.isFirst;
      });
      await showDialog(
          routeSettings: const RouteSettings(name: 'android_alert_dialog'),
          useSafeArea: true,
          context: context,
          builder: (dialogContext) =>
              _AndroidAlertDialog(title, message, description));
      if (onClosed != null) {
        onClosed();
      }
    });

class _AndroidAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String description;

  const _AndroidAlertDialog(this.title, this.message, this.description);

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Stack(fit: StackFit.loose, children: [
      Positioned(
        top: 5,
        right: 5,
        child: IconButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Symbols.close, fill: 1, size: 24),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: 32,
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(
              height: 32,
            ),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      )
    ]));
  }
}
