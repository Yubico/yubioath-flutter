/*
 * Copyright (C) 2022 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../message.dart';
import 'device_avatar.dart';
import 'device_picker_dialog.dart';

class _CircledDeviceAvatar extends ConsumerWidget {
  final double radius;
  const _CircledDeviceAvatar(this.radius);

  @override
  Widget build(BuildContext context, WidgetRef ref) => CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: IconTheme(
          // Force the standard icon theme
          data: IconTheme.of(context),
          child: DeviceAvatar.currentDevice(ref, radius: radius - 1),
        ),
      );
}

class DeviceButton extends ConsumerWidget {
  final double radius;
  const DeviceButton({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.l_select_yk,
      icon: _CircledDeviceAvatar(radius),
      onPressed: () async {
        await showBlurDialog(
          context: context,
          builder: (context) => const DevicePickerDialog(),
          routeSettings: const RouteSettings(name: 'device_picker'),
        );
      },
    );
  }
}
