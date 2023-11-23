/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum SlotId {
  one('one', 1),
  two('two', 2);

  final String id;
  final int numberId;
  const SlotId(this.id, this.numberId);

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      SlotId.one => l10n.s_otp_slot_one,
      SlotId.two => l10n.s_otp_slot_two
    };
  }

  factory SlotId.fromJson(String value) =>
      SlotId.values.firstWhere((e) => e.id == value);
}

enum SlotConfigurationType { yubiotp, static, hotp, chalresp }

@freezed
class OtpState with _$OtpState {
  const OtpState._();
  factory OtpState({
    required bool slot1Configured,
    required bool slot2Configured,
  }) = _OtpState;

  factory OtpState.fromJson(Map<String, dynamic> json) =>
      _$OtpStateFromJson(json);

  List<OtpSlot> get slots => [
        OtpSlot(slot: SlotId.one, isConfigured: slot1Configured),
        OtpSlot(slot: SlotId.two, isConfigured: slot2Configured),
      ];
}

@freezed
class OtpSlot with _$OtpSlot {
  factory OtpSlot({required SlotId slot, required bool isConfigured}) =
      _OtpSlot;
}

@freezed
class SlotConfigurationOptions with _$SlotConfigurationOptions {
  // ignore: invalid_annotation_target
  @JsonSerializable(includeIfNull: false)
  factory SlotConfigurationOptions(
      {bool? digits8,
      bool? requireTouch,
      bool? appendCr}) = _SlotConfigurationOptions;

  factory SlotConfigurationOptions.fromJson(Map<String, dynamic> json) =>
      _$SlotConfigurationOptionsFromJson(json);
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class SlotConfiguration with _$SlotConfiguration {
  const SlotConfiguration._();

  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory SlotConfiguration.hotp(
      {required String key,
      SlotConfigurationOptions? options}) = _SlotConfigurationHotp;

  @FreezedUnionValue('hmac_sha1')
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory SlotConfiguration.chalresp(
      {required String key,
      SlotConfigurationOptions? options}) = _SlotConfigurationHmacSha1;

  @FreezedUnionValue('static_password')
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory SlotConfiguration.static(
      {required String password,
      required String keyboardLayout,
      SlotConfigurationOptions? options}) = _SlotConfigurationStaticPassword;

  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory SlotConfiguration.yubiotp(
      {required String publicId,
      required String privateId,
      required String key,
      SlotConfigurationOptions? options}) = _SlotConfigurationYubiOtp;

  factory SlotConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SlotConfigurationFromJson(json);
}
