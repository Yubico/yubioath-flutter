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
  otp(0x001, 'OTP'),
  piv(0x010, 'PIV'),
  oath(0x020, 'OATH'),
  openpgp(0x008, 'OpenPGP'),
  hsmauth(0x100, 'YubiHSM Auth'),
  u2f(0x002, 'FIDO U2F'),
  fido2(0x200, 'FIDO2');

  final int value;
  final String name;
  const Capability(this.value, this.name);
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
  factory DeviceInfo(
      DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}
