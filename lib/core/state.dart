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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';

bool get isDesktop {
  return const [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux
  ].contains(defaultTargetPlatform);
}

bool get isAndroid {
  return defaultTargetPlatform == TargetPlatform.android;
}

// This must be initialized before use, in main.dart.
final prefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

abstract class ApplicationStateNotifier<T>
    extends AutoDisposeFamilyAsyncNotifier<T, DevicePath> {
  ApplicationStateNotifier() : super();

  @protected
  Future<void> updateState(Future<T> Function() guarded) async {
    state = await AsyncValue.guard(guarded);
  }

  @protected
  void setData(T value) {
    state = AsyncValue.data(value);
  }
}
