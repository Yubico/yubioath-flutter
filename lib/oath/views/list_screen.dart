import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/theme.dart';

import '../../android/oath/state.dart';
import '../../app/models.dart';
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

class ListScreen extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final List<CredentialData>? credentialsFromUri;

  const ListScreen(this.devicePath, this.credentialsFromUri)
      : super(key: setOrManagePasswordAction);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  int? numCreds;
  late Map<CredentialData, bool> checkedCreds;
  late Map<CredentialData, bool> touchEnabled;
  List<OathCredential>? _credentials;

  @override
  void initState() {
    super.initState();
    checkedCreds =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => true);
    touchEnabled =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;
    numCreds = ref.watch(credentialListProvider(widget.devicePath)
        .select((value) => value?.length));
    final deviceNode = ref.watch(currentDeviceProvider);

    _credentials = ref
        .watch(credentialListProvider(deviceNode!.path))
        ?.map((e) => e.credential)
        .toList();

    return ResponsiveDialog(
        title: Text(l10n.s_add_accounts),
        actions: [
          TextButton(
            onPressed: isValid() && areUnique() ? submit : null,
            child: Text(l10n.s_save),
          )
        ],
        child: //Padding(
            //padding: const EdgeInsets.symmetric(horizontal: 18.0),
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Text(l10n.l_select_accounts)),
            //const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
            ...widget.credentialsFromUri!.map(
              (cred) => CheckboxListTile(
                //contentPadding: const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      isSelected: touchEnabled[cred],
                      color: touchEnabled[cred]!
                          ? (darkMode ? primaryGreen : primaryBlue)
                          : null,
                      onPressed: isUnique(cred)
                          ? () {
                              setState(() {
                                touchEnabled[cred] = !touchEnabled[cred]!;
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
                        checkedCreds[cred] = false;
                        checkedCreds[renamed] = true;
                        touchEnabled[renamed] = false;
                      });
                    },
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                  ),
                ]),
                title: Text(getTitle(cred),
                    overflow: TextOverflow.fade, maxLines: 1, softWrap: false),

                value: isUnique(cred) ? (checkedCreds[cred] ?? true) : false,
                enabled: isUnique(cred),
                subtitle: cred.issuer != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Text(cred.name,
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false),
                            isUnique(cred)
                                ? Text('')
                                : Text(
                                    l10n.l_name_already_exists,
                                    style: TextStyle(
                                      color: primaryRed,
                                      fontSize: 12,
                                    ),
                                  )
                          ])
                    : isUnique(cred)
                        ? null
                        : Text(
                            l10n.l_name_already_exists,
                            style: TextStyle(color: primaryRed, fontSize: 12),
                          ),
                onChanged: (bool? value) {
                  setState(() {
                    checkedCreds[cred] = value!;
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

  String getTitle(CredentialData cred) {
    if (cred.issuer != null) {
      return cred.issuer!;
    }
    return cred.name;
  }

  bool areUnique() {
    bool unique = false;
    checkedCreds.forEach((k, v) => unique = unique || isUnique(k));
    return unique;
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
    // If the credential is not unique, make sure the checkbox is not checked.
    if (!ans) {
      checkedCreds[cred] = false;
    }
    return ans;
  }

  bool isValid() {
    int credsToAdd = 0;
    checkedCreds.forEach((k, v) => v ? credsToAdd++ : null);
    if ((credsToAdd > 0) && (numCreds! + credsToAdd <= 32)) return true;
    return false;
  }

  void submit() async {
    checkedCreds.forEach((k, v) => v ? accept(k) : null);
    Navigator.of(context).pop();
  }

  void accept(CredentialData cred) async {
    final deviceNode = ref.watch(currentDeviceProvider);
    final devicePath = deviceNode?.path;
    if (devicePath != null) {
      await _doAddCredential(
          devicePath: devicePath,
          credUri: cred.toUri(),
          requireTouch: touchEnabled[cred]);
    } else if (isAndroid) {
      // Send the credential to Android to be added to the next YubiKey
      await _doAddCredential(devicePath: null, credUri: cred.toUri());
    }
  }

  Future<void> _doAddCredential(
      {DevicePath? devicePath,
      required Uri credUri,
      bool? requireTouch}) async {
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
      showMessage(context, 'added');
    } on CancellationException catch (_) {
      // ignored
    } catch (e) {
      _log.debug('Failed to add account');
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
    }
  }
}
