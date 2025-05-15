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
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models.dart';
import '../../core/state.dart';
import '../../management/models.dart';
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
        badge:
            isDesktop && data.node is NfcReaderNode
                ? const Icon(Symbols.contactless)
                : null,
        radius: radius,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: ProductImage(
            name: data.name,
            formFactor: data.info.formFactor,
            isNfc: data.info.supportedCapabilities.containsKey(Transport.nfc),
          ),
        ),
      );

  factory DeviceAvatar.deviceNode(DeviceNode node, {double? radius}) =>
      switch (node) {
        UsbYubiKeyNode() =>
          node.info != null
              ? DeviceAvatar.yubiKeyData(
                YubiKeyData(node, node.name, node.info!),
                radius: radius,
              )
              : DeviceAvatar(
                radius: radius,
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: ProductImage(
                    name: '',
                    formFactor: FormFactor.unknown,
                    isNfc: false,
                  ),
                ),
              ),

        NfcReaderNode() => DeviceAvatar(
          radius: radius,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Symbols.contactless),
          ),
        ),
      };

  factory DeviceAvatar.currentDevice(WidgetRef ref, {double? radius}) {
    final deviceNode = ref.watch(currentDeviceProvider);
    if (deviceNode != null) {
      return ref
          .watch(currentDeviceDataProvider)
          .maybeWhen(
            data: (data) => DeviceAvatar.yubiKeyData(data, radius: radius),
            orElse: () => DeviceAvatar.deviceNode(deviceNode, radius: radius),
          );
    } else {
      return DeviceAvatar(
        radius: radius,
        key: noDeviceAvatar,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Symbols.usb),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        child,
        if (badge != null)
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.transparent,
            child: IconTheme(
              data: IconTheme.of(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                size: 18,
              ),
              child: badge!,
            ),
          ),
      ],
    );
  }
}
