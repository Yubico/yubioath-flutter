/*
 * Copyright (C) 2026 Yubico.
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

import 'package:flutter_riverpod/legacy.dart';

/// Holds a transient credential for at most three minutes between accesses.
/// Read [value] to renew it; observing provider state does not renew it.
class CachedCredential extends StateNotifier<String?> {
  static const idleTimeout = Duration(minutes: 3);

  final DateTime Function() _now;
  DateTime? _lastAccess;
  Timer? _timer;

  CachedCredential({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(null);

  String? get value {
    if (state == null) return null;
    // Timers may not have run yet when resuming from sleep.
    if (_now().difference(_lastAccess!) >= idleTimeout) {
      value = null;
      return null;
    }
    _refresh();
    return state;
  }

  set value(String? credential) {
    _timer?.cancel();
    _lastAccess = null;
    if (credential != null) _refresh();
    state = credential;
  }

  void _refresh() {
    _lastAccess = _now();
    _timer?.cancel();
    _timer = Timer(idleTimeout, () => value = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
