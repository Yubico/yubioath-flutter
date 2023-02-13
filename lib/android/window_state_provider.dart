/*
 * Copyright (C) 2022-2023 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/models.dart';
import 'app_methods.dart';

final _log = Logger('android.window_state_provider');

final _windowStateProvider =
    StateNotifierProvider<_WindowStateNotifier, WindowState>(
        (ref) => _WindowStateNotifier(ref));

final androidWindowStateProvider = Provider<WindowState>(
  (ref) => ref.watch(_windowStateProvider),
);

class _WindowStateNotifier extends StateNotifier<WindowState>
    with WidgetsBindingObserver {
    final StateNotifierProviderRef<_WindowStateNotifier, WindowState> _ref;
    _WindowStateNotifier(this._ref)
      : super(WindowState(focused: true, visible: true, active: true)) {
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifeCycleState) {
    _log.debug(
        'appLifecycleStateChange triggered with: ${lifeCycleState.name}');

    var requestedState = lifeCycleState == AppLifecycleState.resumed;
    var currentState = state.focused;

    if (requestedState != currentState) {
      state = WindowState(
          focused: requestedState,
          visible: requestedState,
          active: requestedState);
      _log.debug('Updated windowState to $state');
      if (lifeCycleState == AppLifecycleState.resumed) {
        _log.debug('Reading nfc enabled value');
        isNfcEnabled().then((value) =>
            _ref.read(androidNfcStateProvider.notifier).setNfcEnabled(value));
      }
    } else {
      _log.debug('Ignoring appLifecycleStateChange');
    }
  }

  void _init() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
