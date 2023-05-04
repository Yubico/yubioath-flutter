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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../biometrics/biometrics_methods.dart';
import '../biometrics/state.dart';
import '../state.dart';
import '../models.dart';
import '../keys.dart' as keys;

class NfcTapActionView extends ConsumerWidget {
  const NfcTapActionView({super.key});

  Future<NfcTapAction?> _selectTapAction(
          BuildContext context, NfcTapAction tapAction) async =>
      await showDialog<NfcTapAction>(
          context: context,
          builder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            return SimpleDialog(
              title: Text(l10n.l_on_yk_nfc_tap),
              children: NfcTapAction.values
                  .map(
                    (e) => RadioListTile<NfcTapAction>(
                        title: Text(e.getDescription(l10n)),
                        key: keys.nfcTapOption(e),
                        value: e,
                        groupValue: tapAction,
                        toggleable: true,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        }),
                  )
                  .toList(),
            );
          });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tapAction = ref.watch(androidNfcTapActionProvider);
    return ListTile(
      title: Text(l10n.l_on_yk_nfc_tap),
      subtitle: Text(tapAction.getDescription(l10n)),
      key: keys.nfcTapSetting,
      onTap: () async {
        final newTapAction = await _selectTapAction(context, tapAction);
        if (newTapAction != null) {
          await ref
              .read(androidNfcTapActionProvider.notifier)
              .setTapAction(newTapAction);
        }
      },
    );
  }
}

class NfcKbdLayoutView extends ConsumerWidget {
  const NfcKbdLayoutView({super.key});

  Future<String?> _selectKbdLayout(BuildContext context, List<String> available,
          String currentKbdLayout) async =>
      await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            return SimpleDialog(
              title: Text(l10n.s_choose_kbd_layout),
              children: available
                  .map(
                    (e) => RadioListTile<String>(
                        title: Text(e),
                        value: e,
                        key: keys.keyboardLayoutOption(e),
                        toggleable: true,
                        groupValue: currentKbdLayout,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        }),
                  )
                  .toList(),
            );
          });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tapAction = ref.watch(androidNfcTapActionProvider);
    final clipKbdLayout = ref.watch(androidNfcKbdLayoutProvider);
    return ListTile(
      title: Text(l10n.l_kbd_layout_for_static),
      subtitle: Text(clipKbdLayout),
      key: keys.nfcKeyboardLayoutSetting,
      enabled: tapAction != NfcTapAction.launch,
      onTap: () async {
        final newValue = await _selectKbdLayout(
          context,
          ref.watch(androidNfcSupportedKbdLayoutsProvider),
          clipKbdLayout,
        );
        if (newValue != null) {
          await ref
              .read(androidNfcKbdLayoutProvider.notifier)
              .setKeyboardLayout(newValue);
        }
      },
    );
  }
}

class NfcBypassTouchView extends ConsumerWidget {
  const NfcBypassTouchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nfcBypassTouch = ref.watch(androidNfcBypassTouchProvider);
    return SwitchListTile(
        title: Text(l10n.l_bypass_touch_requirement),
        subtitle: Text(nfcBypassTouch
            ? l10n.l_bypass_touch_requirement_on
            : l10n.l_bypass_touch_requirement_off),
        value: nfcBypassTouch,
        key: keys.nfcBypassTouchSetting,
        onChanged: (value) {
          ref
              .read(androidNfcBypassTouchProvider.notifier)
              .setNfcBypassTouch(value);
        });
  }
}

class NfcSilenceSoundsView extends ConsumerWidget {
  const NfcSilenceSoundsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nfcSilenceSounds = ref.watch(androidNfcSilenceSoundsProvider);
    return SwitchListTile(
        title: Text(l10n.s_silence_nfc_sounds),
        subtitle: Text(nfcSilenceSounds
            ? l10n.l_silence_nfc_sounds_on
            : l10n.l_silence_nfc_sounds_off),
        value: nfcSilenceSounds,
        key: keys.nfcSilenceSoundsSettings,
        onChanged: (value) {
          ref
              .read(androidNfcSilenceSoundsProvider.notifier)
              .setNfcSilenceSounds(value);
        });
  }
}

class UsbOpenAppView extends ConsumerWidget {
  const UsbOpenAppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final usbOpenApp = ref.watch(androidUsbLaunchAppProvider);
    return SwitchListTile(
        title: Text(l10n.l_launch_app_on_usb),
        subtitle: Text(usbOpenApp
            ? l10n.l_launch_app_on_usb_on
            : l10n.l_launch_app_on_usb_off),
        value: usbOpenApp,
        key: keys.usbOpenApp,
        onChanged: (value) {
          ref.read(androidUsbLaunchAppProvider.notifier).setUsbLaunchApp(value);
        });
  }
}

class UseBiometricsView extends ConsumerWidget {
  const UseBiometricsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    refreshBiometricProtectionAvailability(ref);
    final available = ref.watch(isBiometricProtectionAvailable);
    final enabled = ref.watch(useBiometricProtection);

    return available
        ? SwitchListTile(
            title: Text(l10n.l_use_biometrics),
            subtitle: Text(enabled
                ? l10n.l_use_biometrics_on
                : l10n.l_use_biometrics_off),
            value: enabled,
            key: keys.useBiometrics,
            onChanged: (value) {
              if (available) {
                ref
                    .read(useBiometricProtection.notifier)
                    .setUseBiometrics(value);
              }
            })
        : ListTile(
            title: Text(l10n.l_use_biometrics),
            subtitle: Text(l10n.l_biometrics_not_supported),
            enabled: false,
          );
  }
}
