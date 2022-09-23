import 'package:flutter/material.dart';

const _prefix = 'android.keys';

const betaDialogView = Key('$_prefix.beta_dialog');

const nfcTapSetting = Key('$_prefix.nfc_tap');
const nfcKeyboardLayoutSetting = Key('$_prefix.nfc_keyboard_layout');
const nfcBypassTouchSetting = Key('$_prefix.nfc_bypass_touch');
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
