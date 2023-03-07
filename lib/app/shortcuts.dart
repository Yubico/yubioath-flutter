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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../about_page.dart';
import '../android/views/android_settings_page.dart';
import '../core/state.dart';
import '../desktop/state.dart';
import '../oath/keys.dart';
import '../settings_page.dart';
import 'message.dart';
import 'models.dart';
import 'state.dart';

class OpenIntent extends Intent {
  const OpenIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class HideIntent extends Intent {
  const HideIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class NextDeviceIntent extends Intent {
  const NextDeviceIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class AboutIntent extends Intent {
  const AboutIntent();
}

class EditIntent extends Intent {
  const EditIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

/// Use cmd on macOS, use ctrl on the other platforms
SingleActivator ctrlOrCmd(LogicalKeyboardKey key) =>
    SingleActivator(key, meta: Platform.isMacOS, control: !Platform.isMacOS);

Widget registerGlobalShortcuts(
        {required WidgetRef ref, required Widget child}) =>
    Actions(
      actions: {
        CloseIntent: CallbackAction<CloseIntent>(onInvoke: (_) {
          windowManager.close();
          return null;
        }),
        HideIntent: CallbackAction<HideIntent>(onInvoke: (_) {
          if (isDesktop) {
            ref.read(desktopWindowStateProvider.notifier).setWindowHidden(true);
          }
          return null;
        }),
        SearchIntent: CallbackAction<SearchIntent>(onInvoke: (intent) {
          // If the OATH view doesn't have focus, but is shown, find and select the search bar.
          final searchContext = searchAccountsField.currentContext;
          if (searchContext != null) {
            if (!Navigator.of(searchContext).canPop()) {
              return Actions.maybeInvoke(searchContext, intent);
            }
          }
          return null;
        }),
        NextDeviceIntent: CallbackAction<NextDeviceIntent>(onInvoke: (_) {
          ref.read(withContextProvider)((context) async {
            if (!Navigator.of(context).canPop()) {
              final attached = ref
                  .read(attachedDevicesProvider)
                  .whereType<UsbYubiKeyNode>()
                  .toList();
              if (attached.length > 1) {
                final current = ref.read(currentDeviceProvider);
                if (current != null && current is UsbYubiKeyNode) {
                  final index = attached.indexOf(current);
                  ref.read(currentDeviceProvider.notifier).setCurrentDevice(
                      attached[(index + 1) % attached.length]);
                }
              }
            }
          });
          return null;
        }),
        SettingsIntent: CallbackAction<SettingsIntent>(onInvoke: (_) {
          ref.read(withContextProvider)((context) async {
            if (!Navigator.of(context).canPop()) {
              await showBlurDialog(
                context: context,
                builder: (context) => Platform.isAndroid
                    ? const AndroidSettingsPage()
                    : const SettingsPage(),
                routeSettings: const RouteSettings(name: 'settings'),
              );
            }
          });
          return null;
        }),
        AboutIntent: CallbackAction<AboutIntent>(onInvoke: (_) {
          ref.read(withContextProvider)((context) async {
            if (!Navigator.of(context).canPop()) {
              await showBlurDialog(
                context: context,
                builder: (context) => const AboutPage(),
                routeSettings: const RouteSettings(name: 'about'),
              );
            }
          });
          return null;
        }),
      },
      child: Shortcuts(
        shortcuts: {
          ctrlOrCmd(LogicalKeyboardKey.keyC): const CopyIntent(),
          ctrlOrCmd(LogicalKeyboardKey.keyW): const HideIntent(),
          ctrlOrCmd(LogicalKeyboardKey.keyF): const SearchIntent(),
          if (isDesktop) ...{
            const SingleActivator(LogicalKeyboardKey.tab, control: true):
                const NextDeviceIntent(),
          },
          if (Platform.isMacOS) ...{
            const SingleActivator(LogicalKeyboardKey.keyQ, meta: true):
                const CloseIntent(),
            const SingleActivator(LogicalKeyboardKey.comma, meta: true):
                const SettingsIntent(),
          },
        },
        child: child,
      ),
    );
