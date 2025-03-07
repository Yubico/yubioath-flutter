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
import '../core/state.dart';
import '../desktop/state.dart';
import 'message.dart';
import 'models.dart';
import 'state.dart';
import 'views/keys.dart';
import 'views/settings_page.dart';

class CloseIntent extends Intent {
  const CloseIntent();
}

class HideIntent extends Intent {
  const HideIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
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

class OpenIntent<T> extends Intent {
  final T target;
  const OpenIntent(this.target);
}

class CopyIntent<T> extends Intent {
  final T target;
  const CopyIntent(this.target);
}

class EditIntent<T> extends Intent {
  final T target;
  const EditIntent(this.target);
}

class DeleteIntent<T> extends Intent {
  final T target;
  const DeleteIntent(this.target);
}

class RefreshIntent<T> extends Intent {
  final T target;
  const RefreshIntent(this.target);
}

/// Use cmd on macOS, use ctrl on the other platforms
SingleActivator ctrlOrCmd(LogicalKeyboardKey key) =>
    SingleActivator(key, meta: Platform.isMacOS, control: !Platform.isMacOS);

/// Common shortcuts for items
class ItemShortcuts<T> extends StatelessWidget {
  final T item;
  final Widget child;
  const ItemShortcuts({super.key, required this.item, required this.child});

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: {
          ctrlOrCmd(LogicalKeyboardKey.keyR): RefreshIntent<T>(item),
          ctrlOrCmd(LogicalKeyboardKey.keyC): CopyIntent<T>(item),
          const SingleActivator(LogicalKeyboardKey.copy): CopyIntent<T>(item),
          const SingleActivator(LogicalKeyboardKey.delete):
              DeleteIntent<T>(item),
          const SingleActivator(LogicalKeyboardKey.enter): OpenIntent<T>(item),
          const SingleActivator(LogicalKeyboardKey.space): OpenIntent<T>(item),
        },
        child: child,
      );
}

/// Global keyboard shortcuts
class GlobalShortcuts extends ConsumerWidget {
  final Widget child;
  const GlobalShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Actions(
        actions: {
          CloseIntent: CallbackAction<CloseIntent>(onInvoke: (_) {
            windowManager.close();
            return null;
          }),
          HideIntent: CallbackAction<HideIntent>(onInvoke: (_) {
            if (isDesktop) {
              ref
                  .read(desktopWindowStateProvider.notifier)
                  .setWindowHidden(true);
            }
            return null;
          }),
          SearchIntent: CallbackAction<SearchIntent>(onInvoke: (intent) {
            // If the view doesn't have focus, but is shown, find and select the search bar.
            final searchContext = searchField.currentContext;
            if (searchContext != null) {
              if (!Navigator.of(searchContext).canPop()) {
                return Actions.maybeInvoke(searchContext, intent);
              }
            }
            return null;
          }),
          NextDeviceIntent: CallbackAction<NextDeviceIntent>(onInvoke: (_) {
            ref.read(withContextProvider)((context) async {
              // Only allow switching keys if no other views are open,
              // with the exception of the drawer.
              if (!Navigator.of(context).canPop() ||
                  scaffoldGlobalKey.currentState?.isDrawerOpen == true) {
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
                  builder: (context) => const SettingsPage(),
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
          EscapeIntent: CallbackAction<EscapeIntent>(
            onInvoke: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: {
            ctrlOrCmd(LogicalKeyboardKey.keyF): const SearchIntent(),
            const SingleActivator(LogicalKeyboardKey.escape):
                const EscapeIntent(),
            if (isDesktop) ...{
              const SingleActivator(LogicalKeyboardKey.tab, control: true):
                  const NextDeviceIntent(),
            },
            if (Platform.isMacOS) ...{
              const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
                  const HideIntent(),
              const SingleActivator(LogicalKeyboardKey.keyQ, meta: true):
                  const CloseIntent(),
              const SingleActivator(LogicalKeyboardKey.comma, meta: true):
                  const SettingsIntent(),
            },
            if (Platform.isWindows) ...{
              const SingleActivator(LogicalKeyboardKey.keyW, control: true):
                  const HideIntent(),
            },
            if (Platform.isLinux) ...{
              const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
                  const CloseIntent(),
            },
          },
          child: child,
        ),
      );
}
