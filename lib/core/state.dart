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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';
import '../widgets/flex_box.dart';

bool get isDesktop => const [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux
    ].contains(defaultTargetPlatform);

bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get isMicrosoftStore =>
    Platform.isWindows &&
    Platform.resolvedExecutable.contains('\\WindowsApps\\');

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

// Feature flags
sealed class BaseFeature {
  String get path;
  String _subpath(String key);

  Feature feature(String key, {bool enabled = true}) =>
      Feature._(this, key, enabled: enabled);
}

class _RootFeature extends BaseFeature {
  _RootFeature._();
  @override
  String get path => '';

  @override
  String _subpath(String key) => key;
}

class Feature extends BaseFeature {
  final BaseFeature parent;
  final String key;
  final bool _defaultState;

  Feature._(this.parent, this.key, {bool enabled = true})
      : _defaultState = enabled;

  @override
  String get path => parent._subpath(key);

  @override
  String _subpath(String key) => '$path.$key';
}

final BaseFeature root = _RootFeature._();

typedef FeatureProvider = bool Function(Feature feature);

final featureFlagProvider =
    StateNotifierProvider<FeatureFlagsNotifier, Map<String, bool>>(
        (_) => FeatureFlagsNotifier());

class FeatureFlagsNotifier extends StateNotifier<Map<String, bool>> {
  FeatureFlagsNotifier() : super({});

  void loadConfig(Map<String, dynamic> config) {
    const falsey = [0, false, null];
    state = {for (final k in config.keys) k: !falsey.contains(config[k])};
  }

  void setFeature(Feature feature, dynamic value) {
    state = {...state, feature.path: value};
  }
}

final featureProvider = Provider<FeatureProvider>((ref) {
  final featureMap = ref.watch(featureFlagProvider);

  bool isEnabled(BaseFeature feature) => switch (feature) {
        _RootFeature() => true,
        Feature() => isEnabled(feature.parent) &&
            (featureMap[feature.path] ?? feature._defaultState),
      };

  return isEnabled;
});

class LayoutNotifier extends StateNotifier<FlexLayout> {
  final String _key;
  final SharedPreferences _prefs;
  LayoutNotifier(this._key, this._prefs)
      : super(_fromName(_prefs.getString(_key)));

  void setLayout(FlexLayout layout) {
    state = layout;
    _prefs.setString(_key, layout.name);
  }

  static FlexLayout _fromName(String? name) => FlexLayout.values.firstWhere(
        (element) => element.name == name,
        orElse: () => FlexLayout.list,
      );
}
