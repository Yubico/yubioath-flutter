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

const defaultPeriod = 30;
const defaultDigits = 6;
const defaultCounter = 0;
const defaultOathType = OathType.totp;
const defaultHashAlgorithm = HashAlgorithm.sha1;

enum HashAlgorithm {
  @JsonValue(0x01)
  sha1('SHA-1'),
  @JsonValue(0x02)
  sha256('SHA-256'),
  @JsonValue(0x03)
  sha512('SHA-512');

  final String displayName;
  const HashAlgorithm(this.displayName);
}

enum OathType {
  @JsonValue(0x10)
  hotp('Counter based'),
  @JsonValue(0x20)
  totp('Time based');

  final String displayName;
  const OathType(this.displayName);
}

enum KeystoreState { unknown, allowed, failed }

@freezed
class OathCredential with _$OathCredential {
  factory OathCredential(
      String deviceId,
      String id,
      String? issuer,
      String name,
      OathType oathType,
      int period,
      bool touchRequired) = _OathCredential;

  factory OathCredential.fromJson(Map<String, dynamic> json) =>
      _$OathCredentialFromJson(json);
}

@freezed
class OathCode with _$OathCode {
  factory OathCode(String value, int validFrom, int validTo) = _OathCode;

  factory OathCode.fromJson(Map<String, dynamic> json) =>
      _$OathCodeFromJson(json);
}

@freezed
class OathPair with _$OathPair {
  factory OathPair(OathCredential credential, OathCode? code) = _OathPair;

  factory OathPair.fromJson(Map<String, dynamic> json) =>
      _$OathPairFromJson(json);
}

@freezed
class OathState with _$OathState {
  factory OathState(
    String deviceId,
    Version version, {
    required bool hasKey,
    required bool remembered,
    required bool locked,
    required KeystoreState keystore,
  }) = _OathState;

  factory OathState.fromJson(Map<String, dynamic> json) =>
      _$OathStateFromJson(json);
}

@freezed
class CredentialData with _$CredentialData {
  const CredentialData._();

  factory CredentialData({
    String? issuer,
    required String name,
    required String secret,
    @Default(defaultOathType) OathType oathType,
    @Default(defaultHashAlgorithm) HashAlgorithm hashAlgorithm,
    @Default(defaultDigits) int digits,
    @Default(defaultPeriod) int period,
    @Default(defaultCounter) int counter,
  }) = _CredentialData;

  factory CredentialData.fromJson(Map<String, dynamic> json) =>
      _$CredentialDataFromJson(json);

  factory CredentialData.fromUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'otpauth') {
      throw ArgumentError('Invalid scheme, must be "otpauth://"');
    }
    final oathType = OathType.values.byName(uri.host.toLowerCase());
    final params = uri.queryParameters;
    String? issuer;
    String name = uri.pathSegments.join('/');
    final nameIndex = name.indexOf(':');
    if (nameIndex >= 0) {
      issuer = name.substring(0, nameIndex);
      name = name.substring(nameIndex + 1);
    }
    return CredentialData(
      issuer: params['issuer'] ?? issuer,
      name: name,
      oathType: oathType,
      hashAlgorithm: HashAlgorithm.values
          .byName(params['algorithm']?.toLowerCase() ?? 'sha1'),
      secret: params['secret']!,
      digits: int.tryParse(params['digits'] ?? '') ?? defaultDigits,
      period: int.tryParse(params['period'] ?? '') ?? defaultPeriod,
      counter: int.tryParse(params['counter'] ?? '') ?? defaultCounter,
    );
  }

  Uri toUri() => Uri(
        scheme: 'otpauth',
        host: oathType.name,
        path: issuer != null ? '$issuer:$name' : name,
        queryParameters: {
          'secret': secret,
          if (oathType == OathType.totp) 'period': period.toString(),
          if (oathType == OathType.hotp) 'counter': counter.toString(),
          if (issuer != null) 'issuer': issuer!,
          if (digits != 6) 'digits': digits.toString(),
          if (hashAlgorithm != HashAlgorithm.sha1)
            'algorithm': hashAlgorithm.name,
        },
      );
}
