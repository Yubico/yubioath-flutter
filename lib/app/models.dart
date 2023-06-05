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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../management/models.dart';
import '../core/models.dart';

part 'models.freezed.dart';

const _listEquality = ListEquality();

enum Availability { enabled, disabled, unsupported }

enum Application {
  oath,
  fido,
  otp,
  piv,
  openpgp,
  hsmauth,
  management;

  const Application();

  bool _inCapabilities(int capabilities) => switch (this) {
        Application.oath => Capability.oath.value & capabilities != 0,
        Application.fido =>
          (Capability.u2f.value | Capability.fido2.value) & capabilities != 0,
        Application.otp => Capability.otp.value & capabilities != 0,
        Application.piv => Capability.piv.value & capabilities != 0,
        Application.openpgp => Capability.openpgp.value & capabilities != 0,
        Application.hsmauth => Capability.hsmauth.value & capabilities != 0,
        Application.management => true,
      };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        Application.oath => l10n.s_authenticator,
        Application.fido => l10n.s_webauthn,
        Application.piv => l10n.s_piv,
        _ => name.substring(0, 1).toUpperCase() + name.substring(1),
      };

  Availability getAvailability(YubiKeyData data) {
    if (this == Application.management) {
      final version = data.info.version;
      final available = (version.major > 4 || // YK5 and up
          (version.major == 4 && version.minor >= 1) || // YK4.1 and up
          version.major == 3); // NEO
      // Management can't be disabled
      return available ? Availability.enabled : Availability.unsupported;
    }

    final int supported =
        data.info.supportedCapabilities[data.node.transport] ?? 0;
    final int enabled =
        data.info.config.enabledCapabilities[data.node.transport] ?? 0;

    return _inCapabilities(supported)
        ? (_inCapabilities(enabled)
            ? Availability.enabled
            : Availability.disabled)
        : Availability.unsupported;
  }
}

@freezed
class YubiKeyData with _$YubiKeyData {
  factory YubiKeyData(DeviceNode node, String name, DeviceInfo info) =
      _YubiKeyData;
}

class DevicePath {
  final List<String> segments;

  DevicePath(List<String> path) : segments = List.unmodifiable(path);

  @override
  bool operator ==(Object other) =>
      other is DevicePath && _listEquality.equals(segments, other.segments);

  @override
  int get hashCode => Object.hashAll(segments);

  String get key => segments.join('/');

  @override
  String toString() => key;
}

@freezed
class DeviceNode with _$DeviceNode {
  const DeviceNode._();
  factory DeviceNode.usbYubiKey(
          DevicePath path, String name, UsbPid pid, DeviceInfo? info) =
      UsbYubiKeyNode;
  factory DeviceNode.nfcReader(DevicePath path, String name) = NfcReaderNode;

  Transport get transport =>
      map(usbYubiKey: (_) => Transport.usb, nfcReader: (_) => Transport.nfc);
}

@freezed
class MenuAction with _$MenuAction {
  factory MenuAction({
    required String text,
    required Widget icon,
    String? trailing,
    Intent? intent,
  }) = _MenuAction;
}

@freezed
class WindowState with _$WindowState {
  factory WindowState({
    required bool focused,
    required bool visible,
    required bool active,
    @Default(false) bool hidden,
  }) = _WindowState;
}
