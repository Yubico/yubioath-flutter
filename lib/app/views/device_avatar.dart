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

import '../../core/models.dart';
import '../../core/state.dart';
import '../../management/models.dart';
import '../../widgets/custom_icons.dart';
import '../../widgets/product_image.dart';
import '../models.dart';
import '../state.dart';
import 'keys.dart';

class DeviceAvatar extends StatelessWidget {
  final Widget child;
  final Widget? badge;
  final double? radius;
  const DeviceAvatar({super.key, required this.child, this.badge, this.radius});

  factory DeviceAvatar.yubiKeyData(YubiKeyData data, {double? radius}) =>
      DeviceAvatar(
        badge: isDesktop && data.node is NfcReaderNode ? nfcIcon : null,
        radius: radius,
        child: ProductImage(
            name: data.name,
            formFactor: data.info.formFactor,
            isNfc: data.info.supportedCapabilities.containsKey(Transport.nfc)),
      );

  factory DeviceAvatar.deviceNode(DeviceNode node, {double? radius}) =>
      node.map(
        usbYubiKey: (node) {
          final info = node.info;
          if (info != null) {
            return DeviceAvatar.yubiKeyData(
              YubiKeyData(node, node.name, info),
              radius: radius,
            );
          }
          return DeviceAvatar(
            radius: radius,
            child: const ProductImage(
              name: '',
              formFactor: FormFactor.unknown,
              isNfc: false,
            ),
          );
        },
        nfcReader: (_) => DeviceAvatar(
          radius: radius,
          child: nfcIcon,
        ),
      );

  factory DeviceAvatar.currentDevice(WidgetRef ref, {double? radius}) {
    final deviceNode = ref.watch(currentDeviceProvider);
    if (deviceNode != null) {
      return ref.watch(currentDeviceDataProvider).maybeWhen(
            data: (data) => DeviceAvatar.yubiKeyData(
              data,
              radius: radius,
            ),
            orElse: () => DeviceAvatar.deviceNode(
              deviceNode,
              radius: radius,
            ),
          );
    } else {
      return DeviceAvatar(
        radius: radius,
        key: noDeviceAvatar,
        child: const Icon(Icons.usb),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = this.radius ?? 20;
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          child: IconTheme(
            data: IconTheme.of(context).copyWith(
              size: radius,
            ),
            child: child,
          ),
        ),
        if (badge != null)
          CircleAvatar(
            radius: radius / 3,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconTheme(
              data: IconTheme.of(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                size: radius * 0.5,
              ),
              child: badge!,
            ),
          ),
      ],
    );
  }
}
