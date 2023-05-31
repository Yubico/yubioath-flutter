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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FsDialog extends StatelessWidget {
  final Widget child;
  const FsDialog({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog.fullscreen(
      backgroundColor: Theme.of(context).colorScheme.background.withAlpha(100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: SingleChildScrollView(child: child),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.close),
              label: Text(l10n.s_close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          )
        ],
      ),
    );
  }
}
