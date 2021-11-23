import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum HashAlgorithm {
  @JsonValue(0x01)
  sha1,
  @JsonValue(0x02)
  sha256,
  @JsonValue(0x03)
  sha512,
}

extension on HashAlgorithm {
  String get name => toString().split('.').last.toUpperCase();
}

enum OathType {
  @JsonValue(0x10)
  hotp,
  @JsonValue(0x20)
  totp,
}

extension on OathType {
  String get name => toString().split('.').last.toUpperCase();
}

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
}

@freezed
class OathState with _$OathState {
  factory OathState(String deviceId, bool hasKey, bool locked) = _OathState;

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
    @Default(OathType.totp) OathType oathType,
    @Default(HashAlgorithm.sha1) HashAlgorithm hashAlgorithm,
    @Default(6) int digits,
    @Default(30) int period,
    @Default(0) int counter,
  }) = _CredentialData;

  factory CredentialData.fromJson(Map<String, dynamic> json) =>
      _$CredentialDataFromJson(json);

  Uri toUri() {
    final path = issuer != null ? '$issuer:$name' : name;
    var uri = 'otpauth://${oathType.name}/$path?secret=$secret';
    switch (oathType) {
      case OathType.hotp:
        uri += '&counter=$counter';
        break;
      case OathType.totp:
        uri += '&period=$period';
        break;
    }
    if (issuer != null) {
      uri += '&issuer=$issuer';
    }
    if (digits != 6) {
      uri += '&digits=$digits';
    }
    if (hashAlgorithm != HashAlgorithm.sha1) {
      uri += '&algorithm=${hashAlgorithm.name}';
    }
    return Uri.parse(uri);
  }
}
