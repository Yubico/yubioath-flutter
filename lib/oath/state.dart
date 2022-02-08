import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../app/state.dart';
import '../core/state.dart';
import 'models.dart';

final log = Logger('oath.state');

final oathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState?, List<String>>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class OathStateNotifier extends StateNotifier<OathState?> {
  OathStateNotifier() : super(null);

  Future<void> reset();
  Future<bool> unlock(String password, {bool remember = false});
  Future<bool> setPassword(String? current, String password);
  Future<bool> unsetPassword(String current);
  Future<void> forgetPassword();
}

final credentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, List<String>>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class OathCredentialListNotifier
    extends StateNotifier<List<OathPair>?> {
  OathCredentialListNotifier() : super(null);

  @override
  @protected
  set state(List<OathPair>? value) {
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  Future<OathCode> calculate(OathCredential credential);
  Future<OathCredential> addAccount(Uri otpauth, {bool requireTouch = false});
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name);
  Future<void> deleteAccount(OathCredential credential);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>(
        (ref) => FavoritesNotifier(ref.watch(prefProvider)));

class FavoritesNotifier extends StateNotifier<List<String>> {
  static const String _key = 'OATH_STATE_FAVORITES';
  final SharedPreferences _prefs;
  FavoritesNotifier(this._prefs) : super(_prefs.getStringList(_key) ?? []);

  toggleFavorite(String credentialId) {
    if (state.contains(credentialId)) {
      state = state.toList()..remove(credentialId);
    } else {
      state = [credentialId, ...state];
    }
    _prefs.setStringList(_key, state);
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
              .toList()
            ..sort((a, b) {
              String searchKey(OathCredential c) => (c.issuer ?? '') + c.name;
              return searchKey(a.credential).compareTo(searchKey(b.credential));
            }),
        );
}
