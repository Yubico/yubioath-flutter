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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/models.dart';

final _log = Logger('android.window_state_provider');

final _windowStateProvider =
    StateNotifierProvider<_WindowStateNotifier, WindowState>(
        (ref) => _WindowStateNotifier());

final androidWindowStateProvider = Provider<WindowState>(
  (ref) => ref.watch(_windowStateProvider),
);

class _WindowStateNotifier extends StateNotifier<WindowState>
    with WidgetsBindingObserver {
  _WindowStateNotifier()
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
