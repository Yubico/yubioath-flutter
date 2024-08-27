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

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/models.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum FormFactor {
  @JsonValue(0)
  unknown,
  @JsonValue(1)
  usbAKeychain,
  @JsonValue(2)
  usbANano,
  @JsonValue(3)
  usbCKeychain,
  @JsonValue(4)
  usbCNano,
  @JsonValue(5)
  usbCLightning,
  @JsonValue(6)
  usbABio,
  @JsonValue(7)
  usbCBio,
}

enum Capability {
  otp(0x001),
  piv(0x010),
  oath(0x020),
  openpgp(0x008),
  hsmauth(0x100),
  u2f(0x002),
  fido2(0x200);

  final int value;
  const Capability(this.value);

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        Capability.otp => l10n.s_capability_otp,
        Capability.piv => l10n.s_capability_piv,
        Capability.oath => l10n.s_capability_oath,
        Capability.openpgp => l10n.s_capability_openpgp,
        Capability.hsmauth => l10n.s_capability_hsmauth,
        Capability.u2f => l10n.s_capability_u2f,
        Capability.fido2 => l10n.s_capability_fido2,
      };
}

@freezed
class DeviceConfig with _$DeviceConfig {
  factory DeviceConfig(
      Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout,
      int? challengeResponseTimeout,
      int? deviceFlags) = _DeviceConfig;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);
}

@freezed
class DeviceInfo with _$DeviceInfo {
  const DeviceInfo._(); // Added constructor

  factory DeviceInfo(
      DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky,
      bool pinComplexity,
      int fipsCapable,
      int fipsApproved,
      int resetBlocked) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  /// Gets the tuple fipsCapable, fipsApproved for the given capability.
  (bool fipsCapable, bool fipsApproved) getFipsStatus(Capability capability) {
    final capable = fipsCapable & capability.value != 0;
    final approved = capable && fipsApproved & capability.value != 0;
    return (capable, approved);
  }
}
