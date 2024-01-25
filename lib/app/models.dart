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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../management/models.dart';
import '../core/models.dart';
import '../core/state.dart';

part 'models.freezed.dart';

const _listEquality = ListEquality();

enum Availability { enabled, disabled, unsupported }

enum Application {
  accounts,
  webauthn,
  fingerprints,
  passkeys,
  slots,
  certificates,
  openpgp,
  hsmauth,
  management;

  const Application();

  bool _inCapabilities(int capabilities) => switch (this) {
        Application.accounts => Capability.oath.value & capabilities != 0,
        Application.webauthn => Capability.u2f.value & capabilities != 0 &&
            Capability.fido2.value & capabilities == 0,
        Application.fingerprints => Capability.fido2.value & capabilities != 0,
        Application.passkeys => Capability.fido2.value & capabilities != 0,
        Application.slots => Capability.otp.value & capabilities != 0,
        Application.certificates => Capability.piv.value & capabilities != 0,
        Application.openpgp => Capability.openpgp.value & capabilities != 0,
        Application.hsmauth => Capability.hsmauth.value & capabilities != 0,
        Application.management => true,
      };

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        Application.accounts => l10n.s_accounts,
        Application.webauthn => l10n.s_webauthn,
        Application.fingerprints => l10n.s_fingerprints,
        Application.passkeys => l10n.s_passkeys,
        Application.certificates => l10n.s_certificates,
        Application.slots => l10n.s_slots,
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

    // TODO: Require credman for passkeys

    if (this == Application.fingerprints) {
      if (!const {FormFactor.usbABio, FormFactor.usbCBio}
          .contains(data.info.formFactor)) {
        return Availability.unsupported;
      }
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

enum ActionStyle { normal, primary, error }

@freezed
class ActionItem with _$ActionItem {
  factory ActionItem({
    required Widget icon,
    required String title,
    String? subtitle,
    String? shortcut,
    Widget? trailing,
    Intent? intent,
    ActionStyle? actionStyle,
    Key? key,
    Feature? feature,
  }) = _ActionItem;
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
