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

const _prefix = 'android.keys';

const betaDialogView = Key('$_prefix.beta_dialog');

const nfcTapSetting = Key('$_prefix.nfc_tap');
const nfcKeyboardLayoutSetting = Key('$_prefix.nfc_keyboard_layout');
const nfcBypassTouchSetting = Key('$_prefix.nfc_bypass_touch');
const nfcPlayDiscoverySoundSetting = Key('$_prefix.nfc_play_discovery_sound');
const usbOpenApp = Key('$_prefix.usb_open_app');
const themeModeSetting = Key('$_prefix.theme_mode');

const okButton = Key('$_prefix.ok');
const manualEntryButton = Key('$_prefix.manual_entry');

const launchTapAction = Key('$_prefix.tap_action_launch');
const copyTapAction = Key('$_prefix.tap_action_copy');
const bothTapAction = Key('$_prefix.tap_action_both');

const themeModeSystem = Key('$_prefix.theme_mode_system');
const themeModeLight = Key('$_prefix.theme_mode_light');
const themeModeDark = Key('$_prefix.theme_mode_dark');


Key keyboardLayoutOption(String name) => Key('$_prefix.keyboard_layout.$name');
