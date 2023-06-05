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
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/state.dart';

import 'nfc_activity_icon.dart';

final _logger = Logger('NfcActivityWidget');

int widgetCount = 0;

class NfcActivityWidget extends ConsumerWidget {
  final double width;
  final double height;
  final Widget Function(NfcActivity)? iconView;

  const NfcActivityWidget(
      {super.key, this.width = 32.0, this.height = 32.0, this.iconView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NfcActivity nfcActivityState = ref.watch(androidNfcActivityProvider);

    _logger.info('State for NfcActivityWidget changed to $nfcActivityState');

    return IgnorePointer(
      child: SizedBox(
          width: width,
          height: height,
          child: iconView?.call(nfcActivityState) ??
              NfcActivityIcon(nfcActivityState)),
    );
  }
}
