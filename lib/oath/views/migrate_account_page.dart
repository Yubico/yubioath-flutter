import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/exception/apdu_exception.dart';
import 'package:yubico_authenticator/theme.dart';

import '../../android/oath/state.dart';
import '../../app/models.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../keys.dart';
import '../models.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../state.dart';
import '../../app/message.dart';

import '../../exception/cancellation_exception.dart';
import 'rename_list_account.dart';

final _log = Logger('oath.views.list_screen');

class MigrateAccountPage extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState? state;
  final List<CredentialData>? credentialsFromUri;

  const MigrateAccountPage(this.devicePath, this.state, this.credentialsFromUri)
      : super(key: migrateAccountAction);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MigrateAccountPageState();
}

class _MigrateAccountPageState extends ConsumerState<MigrateAccountPage> {
  int? _numCreds;
  late Map<CredentialData, bool> _checkedCreds;
  late Map<CredentialData, bool> _touchEnabled;
  late Map<CredentialData, bool> _uniqueCreds;
  List<OathCredential>? _credentials;

  @override
  void initState() {
    super.initState();
    _checkedCreds =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => true);
    _touchEnabled =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => false);
    _uniqueCreds =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final deviceNode = ref.watch(currentDeviceProvider);

    _credentials = ref
        .watch(credentialListProvider(deviceNode!.path))
        ?.map((e) => e.credential)
        .toList();

    _numCreds = ref.watch(credentialListProvider(widget.devicePath)
        .select((value) => value?.length));

    checkForDuplicates();
    // If the credential is not unique, make sure the checkbox is not checked
    uncheckDuplicates();

    return ResponsiveDialog(
        title: Text(l10n.s_add_accounts),
        actions: [
          TextButton(
            onPressed: isValid() ? submit : null,
            child: Text(l10n.s_save),
          )
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Text(l10n.l_select_accounts)),
            ...widget.credentialsFromUri!.map(
              (cred) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isTouchSupported())
                    IconButton(
                        color: _touchEnabled[cred]!
                            ? (darkMode ? primaryGreen : primaryBlue)
                            : null,
                        onPressed: _uniqueCreds[cred]!
                            ? () {
                                setState(() {
                                  _touchEnabled[cred] = !_touchEnabled[cred]!;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.touch_app_outlined)),
                  IconButton(
                    onPressed: () async {
                      final node = ref
                          .watch(currentDeviceDataProvider)
                          .valueOrNull
                          ?.node;
                      final withContext = ref.read(withContextProvider);
                      CredentialData renamed = await withContext(
                          (context) async => await showBlurDialog(
                                context: context,
                                builder: (context) => RenameList(node!, cred,
                                    widget.credentialsFromUri, _credentials),
                              ));

                      setState(() {
                        int index = widget.credentialsFromUri!.indexWhere(
                            (element) =>
                                element.name == cred.name &&
                                (element.issuer == cred.issuer));
                        widget.credentialsFromUri![index] = renamed;
                        _checkedCreds[cred] = false;
                        _checkedCreds[renamed] = true;
                        _touchEnabled[renamed] = false;
                      });
                    },
                    icon: const Icon(Icons.edit_outlined),
                    color: darkMode ? Colors.white : Colors.black,
                  ),
                ]),
                title: Text(getTitle(cred),
                    overflow: TextOverflow.fade, maxLines: 1, softWrap: false),
                value: _uniqueCreds[cred]! ? _checkedCreds[cred] : false,
                enabled: _uniqueCreds[cred]!,
                subtitle: cred.issuer != null || !_uniqueCreds[cred]!
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            if (cred.issuer != null)
                              Text(cred.name,
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                  softWrap: false),
                            if (!_uniqueCreds[cred]!)
                              Text(
                                l10n.l_account_already_exists,
                                style: const TextStyle(
                                  color: primaryRed,
                                  fontSize: 12,
                                ),
                              )
                          ])
                    : null,
                onChanged: (bool? value) {
                  setState(() {
                    _checkedCreds[cred] = value!;
                  });
                },
              ),
            )
          ]
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: e,
                  ))
              .toList(),
        ));
  }

  bool isTouchSupported() {
    bool touch = true;
    if (!(widget.state?.version.isAtLeast(4, 2) ?? true)) {
      // Touch not supported
      touch = false;
    }
    return touch;
  }

  String getTitle(CredentialData cred) {
    if (cred.issuer != null) {
      return cred.issuer!;
    }
    return cred.name;
  }

  void checkForDuplicates() {
    for (var item in _checkedCreds.entries) {
      CredentialData cred = item.key;
      _uniqueCreds[cred] = isUnique(cred);
    }
  }

  void uncheckDuplicates() {
    for (var item in _checkedCreds.entries) {
      CredentialData cred = item.key;

      if (!_uniqueCreds[cred]!) {
        _checkedCreds[cred] = false;
      }
    }
  }

  bool isUnique(CredentialData cred) {
    String nameText = cred.name;
    String? issuerText = cred.issuer ?? '';
    bool ans = _credentials
            ?.where((element) =>
                element.name == nameText &&
                (element.issuer ?? '') == issuerText)
            .isEmpty ??
        true;

    return ans;
  }

  bool isValid() {
    int credsToAdd = 0;
    int? capacity = widget.state!.version.isAtLeast(4) ? 32 : null;
    _checkedCreds.forEach((k, v) => v ? credsToAdd++ : null);
    if ((credsToAdd > 0) &&
        (capacity == null || (_numCreds! + credsToAdd <= capacity))) {
      return true;
    }
    return false;
  }

  void submit() async {
    _checkedCreds.forEach((k, v) => v ? accept(k) : null);
    Navigator.of(context).pop();
  }

  void accept(CredentialData cred) async {
    final deviceNode = ref.watch(currentDeviceProvider);
    final devicePath = deviceNode?.path;
    if (devicePath != null) {
      await _doAddCredential(
          devicePath: devicePath,
          credUri: cred.toUri(),
          requireTouch: _touchEnabled[cred]);
    } else if (isAndroid) {
      // Send the credential to Android to be added to the next YubiKey
      await _doAddCredential(devicePath: null, credUri: cred.toUri());
    }
  }

  Future<void> _doAddCredential(
      {DevicePath? devicePath,
      required Uri credUri,
      bool? requireTouch}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (devicePath == null) {
        assert(isAndroid, 'devicePath is only optional for Android');
        await ref.read(addCredentialToAnyProvider).call(credUri);
      } else {
        await ref
            .read(credentialListProvider(devicePath).notifier)
            .addAccount(credUri, requireTouch: requireTouch!);
      }
      if (!mounted) return;
      //Navigator.of(context).pop();
      showMessage(context, l10n.s_account_added);
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.error('Failed to add account', e);
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else if (e is ApduException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        l10n.l_account_add_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    }
  }
}
