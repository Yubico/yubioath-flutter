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

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../app/models.dart';
import '../core/state.dart';
import 'models.dart';

final yubiOtpOutputProvider =
    StateNotifierProvider<YubiOtpOutputNotifier, File?>(
      (ref) => YubiOtpOutputNotifier(),
    );

class YubiOtpOutputNotifier extends StateNotifier<File?> {
  YubiOtpOutputNotifier() : super(null);

  void setOutput(File? file) {
    state = file;
  }
}

final otpStateProvider = AsyncNotifierProvider.autoDispose
    .family<OtpStateNotifier, OtpState, DevicePath>(throw UnimplementedError());

abstract class OtpStateNotifier extends ApplicationStateNotifier<OtpState> {
  OtpStateNotifier(this.devicePath);
  final DevicePath devicePath;

  Future<String> generateStaticPassword(int length, String layout);
  Future<String> modhexEncodeSerial(int serial);
  Future<Map<String, List<String>>> getKeyboardLayouts();
  Future<String> formatYubiOtpCsv(
    int serial,
    String publicId,
    String privateId,
    String key,
  );
  Future<void> swapSlots();
  Future<void> configureSlot(
    SlotId slot, {
    required SlotConfiguration configuration,
    String? accessCode,
  });
  Future<void> deleteSlot(SlotId slot, {String? accessCode});
}
