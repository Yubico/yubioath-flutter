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

final systrayProvider = Provider((ref) => _Systray(ref));

Future<OathCode?> _calculateCode(
    DevicePath devicePath, OathCredential credential, Ref ref) async {
  try {
    return await (ref.read(credentialListProvider(devicePath).notifier)
            as DesktopCredentialListNotifier)
        .calculate(credential, headless: true);
  } on CancellationException catch (_) {
    return null;
  }
}

String _getIcon() {
  if (Platform.isMacOS) {
    return 'assets/graphics/systray-macos.svg';
  }
  if (Platform.isWindows) {
    return 'assets/graphics/systray.ico';
  }
  return 'assets/graphics/app-icon.png';
}

class _Systray extends TrayListener {
  final Ref _ref;
  int _lastClick = 0;
  DevicePath _devicePath = DevicePath([]);
  Iterable<OathCredential> _credentials = [];
  bool isHidden = false;
  _Systray(this._ref) {
    trayManager.setIcon(_getIcon());
    if (!Platform.isLinux) {
      trayManager.setToolTip('Yubico Authenticator');
    }
    // Doesn't seem to work on Linux
    trayManager.addListener(this);

    isHidden = _ref.read(prefProvider).getBool(windowHidden) ?? false;

    _ref.listen(
      _favoriteAccounts,
      (_, credentials) {
        _credentials = credentials;
        _devicePath = _ref.read(currentDeviceProvider)?.path ?? _devicePath;
        _updateContextMenu();
      },
      fireImmediately: true,
    );
  }

  Future<void> _setHidden(bool hidden) async {
    if (hidden) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
    await windowManager.setSkipTaskbar(hidden);
    await _ref.read(prefProvider).setBool(windowHidden, hidden);
    isHidden = hidden;

    await _updateContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      trayManager.popUpContextMenu();
    } else {
      final prefs = _ref.read(prefProvider);
      if (prefs.getBool(windowHidden) ?? false) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastClick < 500) {
          _lastClick = 0;
          _setHidden(false);
        } else {
          _lastClick = now;
        }
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  Future<void> _updateContextMenu() async {
    final prefs = _ref.read(prefProvider);
    final isHidden = prefs.getBool(windowHidden) ?? false;
    await trayManager.setContextMenu(
      Menu(
        items: [
          ..._credentials.map(
            (e) => MenuItem(
              label: '${e.issuer} (${e.name})',
              onClick: (_) async {
                final code = await _calculateCode(_devicePath, e, _ref);
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
          if (_credentials.isNotEmpty) MenuItem.separator(),
          MenuItem(
            label: isHidden ? 'Show window' : 'Hide window',
            onClick: (_) {
              _setHidden(!isHidden);
            },
          ),
          MenuItem.separator(),
          MenuItem(
              label: 'Quit',
              onClick: (_) {
                windowManager.close();
              }),
        ],
      ),
    );
  }
}
