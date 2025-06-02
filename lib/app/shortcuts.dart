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
import '../generated/l10n/app_localizations.dart';
import 'message.dart';
import 'models.dart';
import 'shortcuts_dialog.dart';
import 'state.dart';
import 'views/keys.dart';
import 'views/settings_page.dart';

abstract class AppIntent extends Intent {
  String getDescription(AppLocalizations l10n);
}

class ShortcutsIntent extends AppIntent {
  ShortcutsIntent();

  @override
  String getDescription(AppLocalizations l10n) =>
      l10n.s_open_keyboard_shortcuts;
}

class CloseIntent extends AppIntent {
  CloseIntent();

  @override
  String getDescription(AppLocalizations l10n) =>
      l10n.s_quit_app(l10n.app_name);
}

class HideIntent extends AppIntent {
  HideIntent();

  @override
  String getDescription(AppLocalizations l10n) =>
      l10n.s_hide_app(l10n.app_name);
}

class SearchIntent extends AppIntent {
  SearchIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_search;
}

class EscapeIntent extends AppIntent {
  EscapeIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_dismiss;
}

class NextDeviceIntent extends AppIntent {
  NextDeviceIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_next_device;
}

class PreviousDeviceItent extends AppIntent {
  PreviousDeviceItent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_previous_device;
}

class SettingsIntent extends AppIntent {
  SettingsIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_open_settings;
}

class AboutIntent extends AppIntent {
  AboutIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_open_help_and_about;
}

class NavigationIntent extends AppIntent {
  NavigationIntent();

  @override
  String getDescription(AppLocalizations l10n) =>
      l10n.s_expand_collapse_navigation;
}

class DetailViewIntent extends AppIntent {
  DetailViewIntent();

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_toggle_menu_bar;
}

class OpenIntent<T> extends AppIntent {
  final T target;
  OpenIntent(this.target);

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_open_item;
}

class CopyIntent<T> extends AppIntent {
  final T target;
  CopyIntent(this.target);

  @override
  String getDescription(AppLocalizations l10n) => l10n.l_copy_to_clipboard;
}

class EditIntent<T> extends AppIntent {
  final T target;
  EditIntent(this.target);

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_edit_item;
}

class DeleteIntent<T> extends AppIntent {
  final T target;
  DeleteIntent(this.target);

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_delete_item;
}

class RefreshIntent<T> extends AppIntent {
  final T target;
  RefreshIntent(this.target);

  @override
  String getDescription(AppLocalizations l10n) => l10n.s_calculate_oath_code;
}

/// Use cmd on macOS, use ctrl on the other platforms
SingleActivator ctrlOrCmd(
  LogicalKeyboardKey key, {
  bool alt = false,
  bool shift = false,
}) => SingleActivator(
  key,
  meta: Platform.isMacOS,
  control: !Platform.isMacOS,
  alt: alt,
  shift: shift,
);

Map<SingleActivator, AppIntent> toShortcuts(
  Map<AppIntent, List<SingleActivator>> intents,
) {
  return {
    for (var entry in intents.entries)
      for (var activator in entry.value) activator: entry.key,
  };
}

Map<AppIntent, List<SingleActivator>> getItemIntents<T>(T item) {
  return {
    RefreshIntent<T>(item): [ctrlOrCmd(LogicalKeyboardKey.keyR)],
    CopyIntent<T>(item): [
      ctrlOrCmd(LogicalKeyboardKey.keyC),
      SingleActivator(LogicalKeyboardKey.copy),
    ],
    DeleteIntent<T>(item): [SingleActivator(LogicalKeyboardKey.delete)],
    OpenIntent<T>(item): [
      SingleActivator(LogicalKeyboardKey.enter),
      SingleActivator(LogicalKeyboardKey.space),
    ],
  };
}

Map<AppIntent, List<SingleActivator>> getGlobalIntents() {
  return {
    ShortcutsIntent(): [
      ctrlOrCmd(LogicalKeyboardKey.numpadDivide),
      ctrlOrCmd(LogicalKeyboardKey.slash),
    ],
    NavigationIntent(): [ctrlOrCmd(LogicalKeyboardKey.keyB)],
    DetailViewIntent(): [ctrlOrCmd(LogicalKeyboardKey.keyB, alt: true)],
    SearchIntent(): [ctrlOrCmd(LogicalKeyboardKey.keyF)],
    EscapeIntent(): [SingleActivator(LogicalKeyboardKey.escape)],

    if (isDesktop) ...{
      NextDeviceIntent(): [
        SingleActivator(LogicalKeyboardKey.tab, control: true),
      ],
      PreviousDeviceItent(): [
        SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
      ],
      AboutIntent(): [SingleActivator(LogicalKeyboardKey.f1)],
    },
    if (Platform.isMacOS) ...{
      HideIntent(): [SingleActivator(LogicalKeyboardKey.keyW, meta: true)],
      CloseIntent(): [SingleActivator(LogicalKeyboardKey.keyQ, meta: true)],
      SettingsIntent(): [SingleActivator(LogicalKeyboardKey.comma, meta: true)],
    },
    if (Platform.isWindows) ...{
      HideIntent(): [SingleActivator(LogicalKeyboardKey.keyW, control: true)],
    },
    if (Platform.isLinux) ...{
      CloseIntent(): [SingleActivator(LogicalKeyboardKey.keyQ, control: true)],
    },
  };
}

/// Common shortcuts for items
class ItemShortcuts<T> extends StatelessWidget {
  final T item;
  final Widget child;
  const ItemShortcuts({super.key, required this.item, required this.child});

  @override
  Widget build(BuildContext context) =>
      Shortcuts(shortcuts: toShortcuts(getItemIntents(item)), child: child);
}

/// Global keyboard shortcuts
class GlobalShortcuts extends ConsumerWidget {
  final Widget child;
  const GlobalShortcuts({super.key, required this.child});

  void _switchDevice(bool next, WidgetRef ref) {
    ref.read(withContextProvider)((context) async {
      // Only allow switching keys if no other views are open,
      // with the exception of the drawer.
      if (!Navigator.of(context).canPop() ||
          scaffoldGlobalKey.currentState?.isDrawerOpen == true) {
        final attached =
            ref
                .read(attachedDevicesProvider)
                .whereType<UsbYubiKeyNode>()
                .toList();
        if (attached.length > 1) {
          final current = ref.read(currentDeviceProvider);
          if (current != null && current is UsbYubiKeyNode) {
            final index = attached.indexOf(current);
            ref
                .read(currentDeviceProvider.notifier)
                .setCurrentDevice(
                  attached[(index + (next ? 1 : -1)) % attached.length],
                );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Actions(
    actions: {
      CloseIntent: CallbackAction<CloseIntent>(
        onInvoke: (_) {
          windowManager.close();
          return null;
        },
      ),
      HideIntent: CallbackAction<HideIntent>(
        onInvoke: (_) {
          if (isDesktop) {
            ref.read(desktopWindowStateProvider.notifier).setWindowHidden(true);
          }
          return null;
        },
      ),
      SearchIntent: CallbackAction<SearchIntent>(
        onInvoke: (intent) {
          // If the view doesn't have focus, but is shown, find and select the search bar.
          final searchContext = searchField.currentContext;
          if (searchContext != null) {
            if (!Navigator.of(searchContext).canPop()) {
              return Actions.maybeInvoke(searchContext, intent);
            }
          }
          return null;
        },
      ),
      NextDeviceIntent: CallbackAction<NextDeviceIntent>(
        onInvoke: (_) {
          _switchDevice(true, ref);
          return null;
        },
      ),
      PreviousDeviceItent: CallbackAction<PreviousDeviceItent>(
        onInvoke: (_) {
          _switchDevice(false, ref);
          return null;
        },
      ),
      SettingsIntent: CallbackAction<SettingsIntent>(
        onInvoke: (_) {
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
        },
      ),
      ShortcutsIntent: CallbackAction<ShortcutsIntent>(
        onInvoke: (_) {
          ref.read(withContextProvider)((context) async {
            if (!Navigator.of(context).canPop()) {
              await showBlurDialog(
                context: context,
                builder: (context) => ShortcutsDialog(),
              );
            }
          });
          return null;
        },
      ),
      NavigationIntent: CallbackAction<NavigationIntent>(
        onInvoke: (_) {
          // Notify to toggle visibility of navigation
          final controller = ref.read(navigationVisibilityProvider.notifier);
          controller.state = !controller.state;
          return null;
        },
      ),
      DetailViewIntent: CallbackAction<DetailViewIntent>(
        onInvoke: (_) {
          // Notify to toggle visibility of detail view
          final controller = ref.read(sideMenuVisibilityProvider.notifier);
          controller.state = !controller.state;
          return null;
        },
      ),
      AboutIntent: CallbackAction<AboutIntent>(
        onInvoke: (_) {
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
        },
      ),
      EscapeIntent: CallbackAction<EscapeIntent>(
        onInvoke: (_) async {
          await ref.read(withContextProvider)((context) async {
            FocusScopeNode mainScope = FocusScope.of(context);
            // Avoid moving focus outside of main scope
            if (!mainScope.hasPrimaryFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          });
          return null;
        },
      ),
    },
    child: Shortcuts(shortcuts: toShortcuts(getGlobalIntents()), child: child),
  );
}
