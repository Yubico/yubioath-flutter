import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state.dart';
import 'models.dart';

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, List<String>>(
  (ref, devicePath) => RpcNodeSession(
    ref.watch(rpcProvider),
    devicePath,
    ['ccid', 'oath'],
    () {
      ref.refresh(_sessionProvider(devicePath));
    },
  ),
);

final oathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState?, List<String>>(
  (ref, devicePath) =>
      OathStateNotifier(ref.watch(_sessionProvider(devicePath)))..refresh(),
);

class OathStateNotifier extends StateNotifier<OathState?> {
  final RpcNodeSession _session;
  OathStateNotifier(this._session) : super(null);

  refresh() async {
    var result = await _session.command('get');
    developer.log('application status',
        name: 'oath', error: jsonEncode(result));
    if (mounted) {
      state = OathState.fromJson(result['data']);
    }
  }

  Future<bool> unlock(String password) async {
    var result =
        await _session.command('derive', params: {'password': password});
    var key = result['key'];
    await _session.command('validate', params: {'key': key});
    if (mounted) {
      developer.log('UNLOCKED');
      state = state?.copyWith(locked: false);
    }
    return true;
  }
}

final credentialListProvider = StateNotifierProvider.autoDispose
    .family<CredentialListNotifier, List<OathPair>?, List<String>>(
  (ref, devicePath) {
    return CredentialListNotifier(
      ref.watch(_sessionProvider(devicePath)),
      ref.watch(oathStateProvider(devicePath).select((s) => s?.locked ?? true)),
    )..refresh();
  },
);

extension on OathCredential {
  bool get isSteam => issuer == 'Steam' && oathType == OathType.totp;
}

const String _steamCharTable = '23456789BCDFGHJKMNPQRTVWXY';
String _formatSteam(String response) {
  final offset = int.parse(response.substring(response.length - 1), radix: 16);
  var number =
      int.parse(response.substring(offset * 2, offset * 2 + 8), radix: 16) &
          0x7fffffff;
  var value = '';
  for (var i = 0; i < 5; i++) {
    value += _steamCharTable[number % _steamCharTable.length];
    number ~/= _steamCharTable.length;
  }
  return value;
}

class CredentialListNotifier extends StateNotifier<List<OathPair>?> {
  final RpcNodeSession _session;
  final bool _locked;
  Timer? _timer;
  CredentialListNotifier(this._session, this._locked) : super(null);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  @protected
  set state(List<OathPair>? value) {
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  calculate(OathCredential credential) async {
    OathCode code;
    if (credential.isSteam) {
      final timeStep = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      var result = await _session.command('calculate', target: [
        'accounts',
        credential.id
      ], params: {
        'challenge': timeStep.toRadixString(16).padLeft(16, '0'),
      });
      code = OathCode(
          _formatSteam(result['response']), timeStep * 30, (timeStep + 1) * 30);
    } else {
      var result =
          await _session.command('code', target: ['accounts', credential.id]);
      code = OathCode.fromJson(result);
    }
    developer.log('Calculate', name: 'oath', error: jsonEncode(code));
    if (mounted) {
      final creds = state!.toList();
      final i = creds.indexWhere((e) => e.credential.id == credential.id);
      state = creds..[i] = creds[i].copyWith(code: code);
    }
  }

  addAccount(Uri otpauth, {bool requireTouch = false}) async {
    var result = await _session.command('put', target: [
      'accounts'
    ], params: {
      'uri': otpauth.toString(),
      'require_touch': requireTouch,
    });
    final credential = OathCredential.fromJson(result);
    if (mounted) {
      state = state!.toList()..add(OathPair(credential, null));
      if (!requireTouch && credential.oathType == OathType.totp) {
        calculate(credential);
      }
    }
  }

  refresh() async {
    if (_locked) return;
    developer.log('refreshing credentials...', name: 'oath');
    var result = await _session.command('calculate_all', target: ['accounts']);
    developer.log('Entries', name: 'oath', error: jsonEncode(result));

    if (mounted) {
      var current = state?.toList() ?? [];
      for (var e in result['entries']) {
        final credential = OathCredential.fromJson(e['credential']);
        final code = e['code'] == null ? null : OathCode.fromJson(e['code']);
        var i = current
            .indexWhere((element) => element.credential.id == credential.id);
        if (i < 0) {
          current.add(OathPair(credential, code));
        } else if (code != null) {
          current[i] = current[i].copyWith(code: code);
        }
      }

      state = current;
      for (var pair in current.where((element) =>
          (element.credential.isSteam && !element.credential.touchRequired))) {
        await calculate(pair.credential);
      }
      _scheduleRefresh();
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expirations = (state ?? [])
        .where((pair) =>
            pair.credential.oathType == OathType.totp &&
            !pair.credential.touchRequired)
        .map((e) => e.code)
        .whereType<OathCode>()
        .map((e) => e.validTo)
        .where((time) => time > now);
    if (expirations.isEmpty) {
      _timer = null;
    } else {
      _timer = Timer(Duration(seconds: expirations.reduce(min) - now), refresh);
    }
  }
}

final favoriteProvider =
    StateNotifierProvider.family<FavoriteNotifier, bool, String>(
  (ref, credentialId) {
    return FavoriteNotifier(credentialId);
  },
);

class FavoriteNotifier extends StateNotifier<bool> {
  final String _id;
  FavoriteNotifier(this._id) : super(false);

  toggleFavorite() {
    state = !state;
  }
}

final searchFilterProvider =
    StateNotifierProvider<SearchFilterNotifier, String>(
        (ref) => SearchFilterNotifier());

class SearchFilterNotifier extends StateNotifier<String> {
  SearchFilterNotifier() : super('');

  setFilter(String value) {
    state = value;
  }
}

final filteredCredentialsProvider = StateNotifierProvider.autoDispose
    .family<FilteredCredentialsNotifier, List<OathPair>, List<OathPair>>(
        (ref, full) {
  final favorites = {
    for (var credential in full.map((e) => e.credential))
      credential: ref.watch(favoriteProvider(credential.id))
  };
  return FilteredCredentialsNotifier(
      full, favorites, ref.watch(searchFilterProvider));
});

class FilteredCredentialsNotifier extends StateNotifier<List<OathPair>> {
  final Map<OathCredential, bool> favorites;
  final String query;
  FilteredCredentialsNotifier(
    List<OathPair> full,
    this.favorites,
    this.query,
  ) : super(full
            .where((pair) =>
                "${pair.credential.issuer ?? ''}:${pair.credential.name}"
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) {
            String searchKey(OathCredential c) =>
                (favorites[c] == true ? '0' : '1') + (c.issuer ?? '') + c.name;
            return searchKey(a.credential).compareTo(searchKey(b.credential));
          }));
}
