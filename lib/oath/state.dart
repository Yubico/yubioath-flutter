import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/models.dart';

import '../app/state.dart';
import '../core/state.dart';
import 'models.dart';

final log = Logger('oath.state');

final _sessionProvider = Provider.autoDispose
    .family<RpcNodeSession, List<String>>((ref, devicePath) =>
        RpcNodeSession(ref.watch(rpcProvider), devicePath, ['ccid', 'oath']));

// This remembers the key for all devices for the duration of the process.
final _lockKeyProvider =
    StateNotifierProvider.family<_LockKeyNotifier, String?, List<String>>(
        (ref, devicePath) => _LockKeyNotifier(null));

class _LockKeyNotifier extends StateNotifier<String?> {
  _LockKeyNotifier(String? state) : super(state);

  setKey(String key) {
    state = key;
  }
}

final oathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState?, List<String>>(
  (ref, devicePath) {
    final session = ref.watch(_sessionProvider(devicePath));
    final notifier = OathStateNotifier(session, ref.read);
    session
      ..setErrorHandler('state-reset', (_) async {
        ref.refresh(_sessionProvider(devicePath));
      })
      ..setErrorHandler('auth-required', (_) async {
        await notifier.refresh();
      });
    ref.onDispose(() {
      session
        ..unserErrorHandler('state-reset')
        ..unserErrorHandler('auth-required');
    });
    return notifier..refresh();
  },
);

class OathStateNotifier extends StateNotifier<OathState?> {
  final RpcNodeSession _session;
  final Reader _read;
  OathStateNotifier(this._session, this._read) : super(null);

  refresh() async {
    var result = await _session.command('get');
    log.config('application status', jsonEncode(result));
    var oathState = OathState.fromJson(result['data']);
    final key = _read(_lockKeyProvider(_session.devicePath));
    if (oathState.locked && key != null) {
      await _session.command('validate', params: {'key': key});
      oathState = oathState.copyWith(locked: false);
    }
    if (mounted) {
      state = oathState;
    }
  }

  Future<bool> unlock(String password) async {
    var result =
        await _session.command('derive', params: {'password': password});
    var key = result['key'];
    await _session.command('validate', params: {'key': key});
    if (mounted) {
      log.config('applet unlocked');
      _read(_lockKeyProvider(_session.devicePath).notifier).setKey(key);
      state = state?.copyWith(locked: false);
    }
    return true;
  }
}

final credentialListProvider = StateNotifierProvider.autoDispose
    .family<CredentialListNotifier, List<OathPair>?, List<String>>(
  (ref, devicePath) {
    var notifier = CredentialListNotifier(
      ref.watch(_sessionProvider(devicePath)),
      ref.watch(oathStateProvider(devicePath).select((s) => s?.locked ?? true)),
    );
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._notifyWindowState(windowState);
    }, fireImmediately: true);
    return notifier;
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

  void _notifyWindowState(WindowState windowState) {
    if (_locked) return;
    if (windowState.active) {
      _scheduleRefresh();
    } else {
      _timer?.cancel();
    }
  }

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

  Future<OathCode> calculate(OathCredential credential,
      {bool update = true}) async {
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
    log.config('Calculate', jsonEncode(code));
    if (update && mounted) {
      final creds = state!.toList();
      final i = creds.indexWhere((e) => e.credential.id == credential.id);
      state = creds..[i] = creds[i].copyWith(code: code);
    }
    return code;
  }

  Future<OathCredential> addAccount(Uri otpauth,
      {bool requireTouch = false, bool update = true}) async {
    var result = await _session.command('put', target: [
      'accounts'
    ], params: {
      'uri': otpauth.toString(),
      'require_touch': requireTouch,
    });
    final credential = OathCredential.fromJson(result);
    if (update && mounted) {
      state = state!.toList()..add(OathPair(credential, null));
      if (!requireTouch && credential.oathType == OathType.totp) {
        calculate(credential);
      }
    }
    return credential;
  }

  refresh() async {
    if (_locked) return;
    log.config('refreshing credentials...');
    var result = await _session.command('calculate_all', target: ['accounts']);
    log.config('Entries', jsonEncode(result));

    var current = state?.toList() ?? [];
    for (var e in result['entries']) {
      final credential = OathCredential.fromJson(e['credential']);
      final code = e['code'] == null
          ? null
          : credential.isSteam // Steam codes require a re-calculate
              ? await calculate(credential, update: false)
              : OathCode.fromJson(e['code']);
      var i = current
          .indexWhere((element) => element.credential.id == credential.id);
      if (i < 0) {
        current.add(OathPair(credential, code));
      } else if (code != null) {
        current[i] = current[i].copyWith(code: code);
      }
    }
    if (mounted) {
      state = current;
      _scheduleRefresh();
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    if (_locked) return;
    if (state == null) {
      refresh();
    } else if (mounted) {
      final expirations = (state ?? [])
          .where((pair) =>
              pair.credential.oathType == OathType.totp &&
              !pair.credential.touchRequired)
          .map((e) => e.code)
          .whereType<OathCode>()
          .map((e) => e.validTo);
      if (expirations.isEmpty) {
        _timer = null;
      } else {
        final earliest = expirations.reduce(min) * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (earliest < now) {
          refresh();
        } else {
          _timer = Timer(Duration(milliseconds: earliest - now), refresh);
        }
      }
    }
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
