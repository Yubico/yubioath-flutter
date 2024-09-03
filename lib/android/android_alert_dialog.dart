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

import '../app/state.dart';
import 'tap_request_dialog.dart';

void showAlertDialog(ref, String title, String message) =>
    ref.read(withContextProvider)((context) async {
      ref.read(androidDialogProvider).closeDialog();
      final l10n = ref.read(l10nProvider);
      Navigator.of(context).popUntil((route) {
        return route.isFirst;
      });
      await showDialog(
          routeSettings: const RouteSettings(name: 'android_alert_dialog'),
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
                title: Text(title),
                actions: [
                  TextButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(l10n.s_close))
                ],
                content: Text(message));
          });
    });
