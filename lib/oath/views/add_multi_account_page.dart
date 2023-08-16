import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/exception/apdu_exception.dart';

import '../../android/oath/state.dart';
import '../../app/models.dart';
import '../../core/models.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../state.dart';
import '../../app/message.dart';

import '../../exception/cancellation_exception.dart';
import 'rename_list_account.dart';

final _log = Logger('oath.views.list_screen');

class OathAddMultiAccountPage extends ConsumerStatefulWidget {
  final DevicePath? devicePath;
  final OathState? state;
  final List<CredentialData>? credentialsFromUri;

  const OathAddMultiAccountPage(
      this.devicePath, this.state, this.credentialsFromUri,
      {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OathAddMultiAccountPageState();
}

class _OathAddMultiAccountPageState
    extends ConsumerState<OathAddMultiAccountPage> {
  int? _numCreds;

  late Map<CredentialData, (bool, bool, bool)> _credStates;
  List<OathCredential>? _credentials;

  @override
  void initState() {
    super.initState();
    _credStates = Map.fromIterable(widget.credentialsFromUri!,
        value: (v) => (true, false, false));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (widget.devicePath != null) {
      _credentials = ref
          .watch(credentialListProvider(widget.devicePath!))
          ?.map((e) => e.credential)
          .toList();

      _numCreds = ref.watch(credentialListProvider(widget.devicePath!)
          .select((value) => value?.length));
    }

    // If the credential is not unique, make sure the checkbox is not checked
    checkForDuplicates();

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
              (cred) {
                final (checked, touch, unique) = _credStates[cred]!;
                return CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isTouchSupported())
                      IconButton(
                          color: touch ? colorScheme.primary : null,
                          onPressed: unique
                              ? () {
                                  setState(() {
                                    _credStates[cred] =
                                        (checked, !touch, unique);
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.touch_app_outlined)),
                    IconButton(
                      onPressed: () async {
                        final node = ref
                            .read(currentDeviceDataProvider)
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
                          _credStates.remove(cred);
                          _credStates[renamed] = (true, touch, true);
                        });
                      },
                      icon: IconTheme(
                          data: IconTheme.of(context),
                          child: const Icon(Icons.edit_outlined)),
                    ),
                  ]),
                  title: Text(cred.issuer ?? cred.name,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false),
                  value: unique && checked,
                  enabled: unique,
                  subtitle: cred.issuer != null || !unique
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              if (cred.issuer != null)
                                Text(cred.name,
                                    overflow: TextOverflow.fade,
                                    maxLines: 1,
                                    softWrap: false),
                              if (!unique)
                                Text(
                                  l10n.l_account_already_exists,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12, // TODO: use Theme
                                  ),
                                )
                            ])
                      : null,
                  onChanged: (bool? value) {
                    setState(() {
                      _credStates[cred] = (value == true, touch, unique);
                    });
                  },
                );
              },
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

  void checkForDuplicates() {
    for (final item in _credStates.entries) {
      CredentialData cred = item.key;
      final (checked, touch, _) = item.value;
      final unique = isUnique(cred);
      _credStates[cred] = (checked && unique, touch, unique);
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
    final credsToAdd = _credStates.values.where((element) => element.$1).length;
    if (widget.state != null) {
      int? capacity = widget.state!.version.isAtLeast(4) ? 32 : null;
      return (credsToAdd > 0) &&
          (capacity == null || (_numCreds! + credsToAdd <= capacity));
    } else {
      return true;
    }
  }

  void submit() async {
    final deviceNode = ref.watch(currentDeviceProvider);
    if (isAndroid &&
        (widget.devicePath == null || deviceNode?.transport == Transport.nfc)) {
      var uris = <String>[];
      var touchRequired = <bool>[];

      // build list of uris and touch required flags for unique credentials
      for (final item in _credStates.entries) {
        CredentialData cred = item.key;
        final (checked, touch, _) = item.value;
        if (checked) {
          uris.add(cred.toUri().toString());
          touchRequired.add(touch);
        }
      }

      await _addCredentials(uris: uris, touchRequired: touchRequired);
    } else {
      _credStates.forEach((cred, value) {
        if (value.$1) {
          accept(cred, value.$2);
        }
      });

      Navigator.of(context).pop();
    }
  }

  Future<void> _addCredentials(
      {required List<String> uris, required List<bool> touchRequired}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(addCredentialsToAnyProvider).call(uris, touchRequired);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, l10n.s_account_added);
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.error('Failed to add multiple accounts', e.toString());
      final String errorMessage;
      if (e is ApduException) {
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

  void accept(CredentialData cred, bool touch) async {
    final l10n = AppLocalizations.of(context)!;
    final devicePath = widget.devicePath;
    try {
      if (devicePath == null) {
        assert(isAndroid, 'devicePath is only optional for Android');
        await ref
            .read(addCredentialToAnyProvider)
            .call(cred.toUri(), requireTouch: touch);
      } else {
        await ref
            .read(credentialListProvider(devicePath).notifier)
            .addAccount(cred.toUri(), requireTouch: touch);
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
