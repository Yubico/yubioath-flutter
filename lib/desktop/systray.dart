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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../app/models.dart';
import '../app/shortcuts.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../exception/cancellation_exception.dart';
import '../oath/models.dart';
import '../oath/state.dart';
import '../oath/views/utils.dart';
import 'oath/state.dart';
import 'state.dart';

final _favoriteAccounts =
    Provider.autoDispose<Pair<DevicePath?, List<OathCredential>>>(
  (ref) {
    final devicePath = ref.watch(currentDeviceProvider)?.path;
    if (devicePath != null) {
      final credentials =
          ref.watch(desktopOathCredentialListProvider(devicePath));
      final favorites = ref.watch(favoritesProvider);
      final listed = credentials
              ?.map((e) => e.credential)
              .where((c) => favorites.contains(c.id))
              .toList() ??
          [];
      return Pair(devicePath, listed);
    }
    return Pair(null, []);
  },
);

final systrayProvider = Provider.autoDispose((ref) {
  final systray = _Systray(ref);

  // Keep track of which accounts to show
  ref.listen(
    _favoriteAccounts,
    (_, next) {
      systray._updateCredentials(next);
    },
  );

  // Keep track of the shown/hidden state of the app
  ref.listen(windowStateProvider.select((value) => value.hidden), (_, hidden) {
    systray._setHidden(hidden);
  }, fireImmediately: true);

  ref.onDispose(systray.dispose);

  return systray;
});

Future<OathCode?> _calculateCode(
    DevicePath devicePath, OathCredential credential, Ref ref) async {
  try {
    return await (ref
            .read(desktopOathCredentialListProvider(devicePath).notifier))
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
  List<OathCredential> _credentials = [];
  bool _isHidden = false;
  _Systray(this._ref) {
    _init();
  }

  Future<void> _init() async {
    await trayManager.setIcon(_getIcon(), isTemplate: true);
    if (!Platform.isLinux) {
      await trayManager.setToolTip('Yubico Authenticator');
    }
    await _updateContextMenu();

    // Doesn't seem to work on Linux
    trayManager.addListener(this);
  }

  void dispose() {
    trayManager.destroy();
  }

  void _updateCredentials(Pair<DevicePath?, List<OathCredential>> pair) {
    if (!listEquals(_credentials, pair.second)) {
      _devicePath = pair.first ?? _devicePath;
      _credentials = pair.second;
      _updateContextMenu();
    }
  }

  Future<void> _setHidden(bool hidden) async {
    _isHidden = hidden;
    await _updateContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      trayManager.popUpContextMenu();
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastClick < 500) {
        _lastClick = 0;
        if (_isHidden) {
          _ref.read(desktopWindowStateProvider.notifier).setWindowHidden(false);
        } else {
          windowManager.focus();
        }
      } else {
        _lastClick = now;
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  Future<void> _updateContextMenu() async {
    await trayManager.setContextMenu(
      Menu(
        items: [
          ..._credentials.map(
            (e) {
              final label = getTextName(e);
              return MenuItem(
                label: label,
                onClick: (_) async {
                  final code = await _calculateCode(_devicePath, e, _ref);
                  if (code != null) {
                    await _ref
                        .read(clipboardProvider)
                        .setText(code.value, isSensitive: true);
                    final notification = LocalNotification(
                      title: 'Code copied',
                      body: '$label copied to clipboard.',
                      silent: true,
                    );
                    await notification.show();
                    await Future.delayed(const Duration(seconds: 4));
                    await notification.close();
                  }
                },
              );
            },
          ),
          if (_credentials.isNotEmpty) MenuItem.separator(),
          MenuItem(
            label: _isHidden ? 'Show window' : 'Hide window',
            onClick: (_) {
              _ref
                  .read(desktopWindowStateProvider.notifier)
                  .setWindowHidden(!_isHidden);
            },
          ),
          MenuItem.separator(),
          MenuItem(
              label: 'Quit',
              onClick: (_) {
                _ref.read(withContextProvider)(
                  (context) async {
                    Actions.invoke(context, const CloseIntent());
                  },
                );
              }),
        ],
      ),
    );
  }
}