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

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import '../exception/cancellation_exception.dart';
import '../oath/models.dart';
import '../oath/state.dart';
import 'oath/state.dart';

const String windowHidden = 'DESKTOP_WINDOW_HIDDEN';

final _favoriteAccounts = Provider((ref) {
  final credentials = ref.watch(currentOathCredentialsProvider);
  final favorites = ref.watch(favoritesProvider);
  return credentials.where((element) => favorites.contains(element.id));
});

final systrayProvider = Provider((ref) {
  return Systray(ref);
});

Future<OathCode?> _calculateCode(
    DevicePath devicePath, OathCredential credential, Ref ref) async {
  try {
    return await ref
        .read(credentialListProvider(devicePath).notifier)
        .calculate(credential);
  } on CancellationException catch (_) {
    return null;
  }
}

class Systray extends TrayListener {
  final Ref _ref;
  int _lastClick = 0;
  Systray(this._ref) {
    _init();
  }

  void _init() async {
    await trayManager.setIcon(Platform.isWindows
        ? 'assets/graphics/systray.ico'
        : 'assets/graphics/app-icon.png');
    if (!Platform.isLinux) {
      await trayManager.setToolTip('Yubico Authenticator');
    }
    // Doesn't seem to work on Linux
    trayManager.addListener(this);

    _ref.listen(
      _favoriteAccounts,
      (_, credentials) {
        _updateContextMenu(credentials);
      },
      fireImmediately: true,
    );
  }

  @override
  void onTrayIconMouseDown() async {
    final prefs = _ref.read(prefProvider);
    if (prefs.getBool(windowHidden) ?? false) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastClick < 500) {
        _lastClick = 0;
        await windowManager.show();
        await windowManager.setSkipTaskbar(false);
        await prefs.setBool(windowHidden, false);
      } else {
        _lastClick = now;
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  Future<void> _updateContextMenu(Iterable<OathCredential> credentials) async {
    final devicePath = _ref.read(currentDeviceProvider)?.path;
    await trayManager.setContextMenu(
      Menu(
        items: [
          ...credentials.map(
            (e) => MenuItem(
              label: '${e.issuer} (${e.name})',
              onClick: (_) async {
                final code = await _calculateCode(devicePath!, e, _ref);
                if (code != null) {
                  final clipboard = _ref.read(clipboardProvider);
                  await clipboard.setText(code.value, isSensitive: true);

                  final notification = LocalNotification(
                    title: 'Code copied',
                    body: '${e.issuer} (${e.name}) copied to clipboard.',
                    silent: true,
                  );
                  await notification.show();
                  await Future.delayed(const Duration(seconds: 4));
                  await notification.close();
                }
              },
            ),
          ),
          if (credentials.isNotEmpty) MenuItem.separator(),
          MenuItem(
            label: 'Show/Hide window',
            onClick: (_) async {
              final prefs = _ref.read(prefProvider);
              if (prefs.getBool(windowHidden) ?? false) {
                await windowManager.show();
                await windowManager.setSkipTaskbar(false);
                await prefs.setBool(windowHidden, false);
              } else {
                await windowManager.hide();
                await windowManager.setSkipTaskbar(true);
                await prefs.setBool(windowHidden, true);
              }
            },
          ),
          MenuItem.separator(),
          MenuItem(
              label: 'Quit',
              onClick: (_) async {
                await windowManager.close();
              }),
        ],
      ),
    );
  }
}
