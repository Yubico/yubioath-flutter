import 'package:flutter/material.dart';

// widget key names
const betaDialogKey = Key('android.beta.dialog');
const gotItBtn = Key('android.beta.dialog.btn.got_it');

const settingsOnNfcTapOptionKey = Key('android.settings.option.on_nfc_tap');
const settingsOnNfcTapLaunch = Key('android.settings.on_nfc_tap.launch');
const settingsOnNfcTapCopy = Key('android.settings.on_nfc_tap.copy');
const settingsOnNfcTapBoth = Key('android.settings.on_nfc_tap.both');
const settingsKeyboardLayoutOptionKey = Key('android.settings.option.keyboard_layout');
const settingsKeyboardLayoutUS = Key('android.settings.keyboard_layout.US');
const settingsKeyboardLayoutDE = Key('android.settings.keyboard_layout.DE');
const settingsKeyboardLayoutDECH = Key('android.settings.keyboard_layout.DE-CH');
const settingsBypassTouchKey = Key('android.settings.bypass_touch');

// shared preferences keys
const betaDialogPrefName = 'prefBetaDialogShouldBeShown';
const prefNfcOpenApp = 'prefNfcOpenApp';
const prefNfcBypassTouch = 'prefNfcBypassTouch';
const prefNfcCopyOtp = 'prefNfcCopyOtp';
const prefClipKbdLayout = 'prefClipKbdLayout';
