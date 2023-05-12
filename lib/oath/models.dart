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

import 'dart:typed_data';
import 'dart:convert';
import 'package:base32/base32.dart';
import 'package:logging/logging.dart';
import 'package:convert/convert.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../core/models.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const defaultPeriod = 30;
const defaultDigits = 6;
const defaultCounter = 0;
const defaultOathType = OathType.totp;
const defaultHashAlgorithm = HashAlgorithm.sha1;

final _log = Logger('oath.models');

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
  hotp,
  @JsonValue(0x20)
  totp;

  const OathType();

  String getDisplayName(AppLocalizations l10n) => switch (this) {
        OathType.hotp => l10n.s_counter_based,
        OathType.totp => l10n.s_time_based
      };
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
    List<dynamic> read(Uint8List bytes) {
      final index = bytes[0];
      final sublist1 = bytes.sublist(1, index + 1);
      final sublist2 = bytes.sublist(index + 1);
      return [sublist1, sublist2];
    }

    String b32Encode(Uint8List data) {
      final encodedData = base32.encode(data);
      return utf8.decode(encodedData.runes.toList());
    }

    if (uri.scheme.toLowerCase() == 'otpauth-migration') {
      final uriString = uri.toString();
      var data = Uint8List.fromList(
          base64.decode(Uri.decodeComponent(uriString.split('=')[1])));

      var credentials = <CredentialData>[];

      var tag = data[0];

      /*
      Assuming the credential(s) follow the format:
      cred = 0aLENGTH0aSECRET12NAME1aISSUER200128013002xxx
      where xxx can be another cred.
      */
      while (tag == 10) {
        // 0a tag means new credential.

        //var length = data[1]; // The length of this credential
        var secretTag = data[2];
        if (secretTag != 10) {
          // tag before secret is 0a hex
          throw ArgumentError('Invalid scheme, no secret tag');
        }
        data = data.sublist(3);
        final result1 = read(data);
        final secret = result1[0];
        data = result1[1];
        final decodedSecret = b32Encode(secret);

        var nameTag = data[0];
        if (nameTag != 18) {
          // tag before name is 12 hex
          throw ArgumentError('Invalid scheme, no name tag');
        }
        data = data.sublist(1);
        final result2 = read(data);
        final name = result2[0];
        data = result2[1];

        var issuerTag = data[0];
        List<int>? issuer;

        if (issuerTag == 26) {
          // tag before issuer is 1a hex, but issuer is optional.
          data = data.sublist(1);
          final result3 = read(data);
          issuer = result3[0];
          data = result3[1];
        }
        final credential = CredentialData(
          issuer: issuerTag != 26
              ? null
              : utf8.decode(issuer!, allowMalformed: true),
          name: utf8.decode(name, allowMalformed: true),
          secret: decodedSecret,
        );

        credentials.add(credential);

        var endTag = data.sublist(0, 6);
        if (hex.encode(endTag) != '200128013002') {
          // At the end of every credential there is 200128013002
          throw ArgumentError('Invalid scheme, no end tag');
        }
        data = data.sublist(6);
        tag = data[0];
      }

      // Print all the extracted credentials
      for (var credential in credentials) {
        _log.debug(
            '${credential.issuer} (${credential.name}) ${credential.secret}');
      }

      return credentials[0]; // For now, return only the first credential.
    } else if (uri.scheme.toLowerCase() != 'otpauth') {
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
