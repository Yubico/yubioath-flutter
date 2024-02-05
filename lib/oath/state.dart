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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import 'models.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, String>((ref) => SearchNotifier());

class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  void setFilter(String value) {
    state = value;
  }
}

final oathStateProvider = AsyncNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class OathStateNotifier extends ApplicationStateNotifier<OathState> {
  Future<void> reset();

  /// Unlocks the session and returns a record of `success`, `remembered`.
  Future<(bool, bool)> unlock(String password, {bool remember = false});

  Future<bool> setPassword(String? current, String password);
  Future<bool> unsetPassword(String current);
  Future<void> forgetPassword();
}

final credentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class OathCredentialListNotifier
    extends StateNotifier<List<OathPair>?> {
  OathCredentialListNotifier() : super(null);

  @override
  @protected
  set state(List<OathPair>? value) {
    super.state = value != null
        ? List.unmodifiable(value
          ..sort((a, b) {
            String searchKey(OathCredential c) =>
                ((c.issuer ?? '') + c.name).toLowerCase();
            return searchKey(a.credential).compareTo(searchKey(b.credential));
          }))
        : null;
  }

  Future<OathCode> calculate(OathCredential credential);
  Future<OathCredential> addAccount(Uri otpauth, {bool requireTouch = false});
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name);
  Future<void> deleteAccount(OathCredential credential);
}

final credentialsProvider = StateNotifierProvider.autoDispose<
    _CredentialsProviderNotifier, List<OathCredential>?>((ref) {
  final provider = _CredentialsProviderNotifier();
  final node = ref.watch(currentDeviceProvider);
  if (node != null) {
    ref.listen<List<OathPair>?>(credentialListProvider(node.path),
        (previous, next) {
      provider._updatePairs(next);
    }, fireImmediately: true);
  }
  return provider;
});

class _CredentialsProviderNotifier
    extends StateNotifier<List<OathCredential>?> {
  _CredentialsProviderNotifier() : super(null);

  void _updatePairs(List<OathPair>? pairs) {
    if (mounted) {
      if (pairs == null) {
        if (state != null) {
          state = null;
        }
      } else {
        final creds = pairs.map((p) => p.credential).toList();
        if (!const ListEquality().equals(creds, state)) {
          state = creds;
        }
      }
    }
  }
}

final codeProvider =
    Provider.autoDispose.family<OathCode?, OathCredential>((ref, credential) {
  final node = ref.watch(currentDeviceProvider);
  if (node != null) {
    return ref
        .watch(credentialListProvider(node.path)
            .select((pairs) => pairs?.firstWhere(
                  (pair) => pair.credential == credential,
                  orElse: () => OathPair(credential, null),
                )))
        ?.code;
  }
  return null;
});

final expiredProvider =
    StateNotifierProvider.autoDispose.family<_ExpireNotifier, bool, int>(
  (ref, expiry) =>
      _ExpireNotifier(DateTime.now().millisecondsSinceEpoch, expiry * 1000),
);

class _ExpireNotifier extends StateNotifier<bool> {
  Timer? _timer;
  _ExpireNotifier(int now, int expiry) : super(expiry <= now) {
    if (expiry > now) {
      _timer = Timer(Duration(milliseconds: expiry - now), () {
        if (mounted) {
          state = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>(
        (ref) => FavoritesNotifier(ref.watch(prefProvider)));

class FavoritesNotifier extends StateNotifier<List<String>> {
  static const String _key = 'OATH_STATE_FAVORITES';
  final SharedPreferences _prefs;
  FavoritesNotifier(this._prefs) : super(_prefs.getStringList(_key) ?? []);

  void toggleFavorite(String credentialId) {
    if (state.contains(credentialId)) {
      state = state.toList()..remove(credentialId);
    } else {
      state = [credentialId, ...state];
    }
    _prefs.setStringList(_key, state);
  }

  void renameCredential(String oldCredentialId, String newCredentialId) {
    if (state.contains(oldCredentialId)) {
      state = [newCredentialId, ...state.toList()..remove(oldCredentialId)];
      _prefs.setStringList(_key, state);
    }
  }
}

final filteredCredentialsProvider = StateNotifierProvider.autoDispose
    .family<FilteredCredentialsNotifier, List<OathPair>, List<OathPair>>(
        (ref, full) {
  return FilteredCredentialsNotifier(full, ref.watch(searchProvider));
});

class FilteredCredentialsNotifier extends StateNotifier<List<OathPair>> {
  final String query;
  FilteredCredentialsNotifier(
    List<OathPair> full,
    this.query,
  ) : super(
          full
              .where((pair) =>
                  "${pair.credential.issuer ?? ''}:${pair.credential.name}"
                      .toLowerCase()
                      .contains(query.toLowerCase()))
              .where((pair) => pair.credential.issuer != '_hidden')
              .toList(),
        );
}
