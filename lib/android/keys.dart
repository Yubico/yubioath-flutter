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

import 'package:flutter/material.dart';

import 'models.dart';

const _prefix = 'android.keys';

const okButton = Key('$_prefix.ok');
const manualEntryButton = Key('$_prefix.manual_entry');
const readFromImage = Key('$_prefix.read_image_file');

const nfcBypassTouchSetting = Key('$_prefix.nfc_bypass_touch');
const nfcSilenceSoundsSettings = Key('$_prefix.nfc_silence_sounds');
const usbOpenApp = Key('$_prefix.usb_open_app');

const nfcTapSetting = Key('$_prefix.nfc_tap');
Key nfcTapOption(NfcTapAction action) =>
    Key('$_prefix.tap_action.${action.name}');

const nfcKeyboardLayoutSetting = Key('$_prefix.nfc_keyboard_layout');
Key keyboardLayoutOption(String name) => Key('$_prefix.keyboard_layout.$name');
