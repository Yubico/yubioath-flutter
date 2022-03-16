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

enum Capability { otp, piv, oath, openpgp, hsmauth, u2f, fido2 }

extension CapabilityExtension on Capability {
  int get value {
    switch (this) {
      case Capability.otp:
        return 0x001;
      case Capability.u2f:
        return 0x002;
      case Capability.openpgp:
        return 0x008;
      case Capability.piv:
        return 0x010;
      case Capability.oath:
        return 0x020;
      case Capability.hsmauth:
        return 0x100;
      case Capability.fido2:
        return 0x200;
    }
  }

  String get name {
    switch (this) {
      case Capability.otp:
        return 'OTP';
      case Capability.u2f:
        return 'FIDO U2F';
      case Capability.openpgp:
        return 'OpenPGP';
      case Capability.piv:
        return 'PIV';
      case Capability.oath:
        return 'OATH';
      case Capability.hsmauth:
        return 'YubiHSM Auth';
      case Capability.fido2:
        return 'FIDO2';
    }
  }
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
