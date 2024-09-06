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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state.dart';
import 'models.dart';
import 'nfc_activity_overlay.dart';
import 'nfc_content_widget.dart';

NfcEventCommand autoClose(
        {required String title,
        required String subtitle,
        required Widget icon,
        bool showIfHidden = true}) =>
    setNfcView(
        _NfcAutoCloseWidget(
          child: NfcContentWidget(
            title: title,
            subtitle: subtitle,
            icon: icon,
          ),
        ),
        showIfHidden: showIfHidden);

class _NfcAutoCloseWidget extends ConsumerWidget {
  final Widget child;

  const _NfcAutoCloseWidget({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(androidNfcActivityProvider, (previous, current) {
      if (current == NfcActivity.ready) {
        ref.read(nfcEventCommandNotifier.notifier).sendCommand(hideNfcView());
      }
    });

    return child;
  }
}
