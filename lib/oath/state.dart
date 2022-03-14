import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'models.dart';

final oathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, ApplicationStateResult<OathState>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class OathStateNotifier extends ApplicationStateNotifier<OathState> {
  OathStateNotifier() : super();

  Future<void> reset();

  /// Unlocks the session and returns a Pair of `success`, `remembered`.
  Future<Pair<bool, bool>> unlock(String password, {bool remember = false});

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
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  Future<OathCode> calculate(OathCredential credential);
  Future<OathCredential> addAccount(Uri otpauth, {bool requireTouch = false});
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name);
  Future<void> deleteAccount(OathCredential credential);
}

final credentialsProvider = Provider.autoDispose<List<OathCredential>?>((ref) {
  final node = ref.watch(currentDeviceProvider);
  if (node != null) {
    return ref.watch(credentialListProvider(node.path)
        .select((pairs) => pairs?.map((e) => e.credential).toList()));
  }
  return null;
});

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
  dispose() {
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
