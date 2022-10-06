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
import 'package:freezed_annotation/freezed_annotation.dart';

import '../management/models.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum Transport { usb, nfc }

enum UsbInterface {
  otp(0x01),
  fido(0x02),
  ccid(0x04);

  final int value;
  const UsbInterface(this.value);

  static int forCapabilites(int capabilities) {
    var interfaces = 0;
    if (capabilities & Capability.otp.value != 0) {
      interfaces |= UsbInterface.otp.value;
    }
    if (capabilities & (Capability.u2f.value | Capability.fido2.value) != 0) {
      interfaces |= UsbInterface.fido.value;
    }
    if (capabilities &
            (Capability.openpgp.value |
                Capability.piv.value |
                Capability.oath.value |
                Capability.hsmauth.value) !=
        0) {
      interfaces |= UsbInterface.ccid.value;
    }
    return interfaces;
  }
}

@JsonEnum(alwaysCreate: true)
enum UsbPid {
  @JsonValue(0x0010)
  yksOtp,
  @JsonValue(0x0110)
  neoOtp,
  @JsonValue(0x0111)
  neoOtpCcid,
  @JsonValue(0x0112)
  neoCcid,
  @JsonValue(0x0113)
  neoFido,
  @JsonValue(0x0114)
  neoOtpFido,
  @JsonValue(0x0115)
  neoFidoCcid,
  @JsonValue(0x0116)
  neoOtpFidoCcid,
  @JsonValue(0x0120)
  skyFido,
  @JsonValue(0x0401)
  yk4Otp,
  @JsonValue(0x0402)
  yk4Fido,
  @JsonValue(0x0403)
  yk4OtpFido,
  @JsonValue(0x0404)
  yk4Ccid,
  @JsonValue(0x0405)
  yk4OtpCcid,
  @JsonValue(0x0406)
  yk4FidoCcid,
  @JsonValue(0x0407)
  yk4OtpFidoCcid,
  @JsonValue(0x0410)
  ykpOtpFido;

  int get value => _$UsbPidEnumMap[this]!;

  String get displayName {
    switch (this) {
      case UsbPid.yksOtp:
        return 'YubiKey Standard';
      case UsbPid.ykpOtpFido:
        return 'YubiKey Plus';
      case UsbPid.skyFido:
        return 'Security Key by Yubico';
      default:
        final prefix = name.startsWith('neo') ? 'YubiKey NEO' : 'YubiKey';
        final suffix = UsbInterface.values
            .where((e) => e.value & usbInterfaces != 0)
            .map((e) => e.name.toUpperCase())
            .join('+');
        return '$prefix $suffix';
    }
  }

  int get usbInterfaces => UsbInterface.values
      .where(
          (e) => name.contains(e.name[0].toUpperCase() + e.name.substring(1)))
      .map((e) => e.value)
      .sum;

  static UsbPid fromValue(int value) {
    return UsbPid.values.firstWhere((pid) => pid.value == value);
  }
}

@freezed
class Version with _$Version implements Comparable<Version> {
  const Version._();
  @Assert('major >= 0')
  @Assert('major < 256')
  @Assert('minor >= 0')
  @Assert('minor < 256')
  @Assert('patch >= 0')
  @Assert('patch < 256')
  const factory Version(int major, int minor, int patch) = _Version;

  factory Version.fromJson(List<dynamic> values) {
    return Version(values[0], values[1], values[2]);
  }

  List<dynamic> toJson() => [major, minor, patch];

  @override
  String toString() {
    return '$major.$minor.$patch';
  }

  bool isAtLeast(int major, [int minor = 0, int patch = 0]) =>
      compareTo(Version(major, minor, patch)) >= 0;

  @override
  int compareTo(Version other) {
    final a = major << 16 | minor << 8 | patch;
    final b = other.major << 16 | other.minor << 8 | other.patch;
    return a - b;
  }
}

@freezed
class Pair<T1, T2> with _$Pair<T1, T2> {
  factory Pair(T1 first, T2 second) = _Pair<T1, T2>;
}
