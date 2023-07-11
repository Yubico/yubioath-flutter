import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

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
  bool isChecked = true;
  int? numCreds;
  late Map<CredentialData, bool> checkedCreds;
  List<OathCredential>? _credentials;

  bool unique = true;

  @override
  void initState() {
    super.initState();
    checkedCreds =
        Map.fromIterable(widget.credentialsFromUri!, value: (v) => true);
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: isValid() ? submit : null,
            child: Text(l10n.s_save),
          )
        ],
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                Text(l10n.l_select_accounts),
                //Padding(padding: EdgeInsets.only(top: 20.0, bottom: 2.0)),
                ...widget.credentialsFromUri!.map(
                  (cred) => CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          onPressed: () async {
                            _log.debug('pressed');
                          },
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
                                      builder: (context) => RenameList(
                                          node!,
                                          cred,
                                          widget.credentialsFromUri,
                                          _credentials),
                                    ));

                            setState(() {
                              int index = widget.credentialsFromUri!.indexWhere(
                                  (element) =>
                                      element.name == cred.name &&
                                      (element.issuer == cred.issuer));
                              widget.credentialsFromUri![index] = renamed;
                              checkedCreds[cred] = false;
                              checkedCreds[renamed] = true;
                            });
                          },
                          icon: const Icon(Icons.edit_outlined)),
                    ]),
                    title: cred.issuer != null
                        ? Text(cred.issuer!)
                        : Text(cred.name),
                    value: isUnique(cred.name, cred.issuer ?? '')
                        ? (checkedCreds[cred] ?? true)
                        : false,
                    enabled: isUnique(cred.name, cred.issuer ?? ''),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          cred.issuer != null ? Text(cred.name) : Text(''),
                          isUnique(cred.name, cred.issuer ?? '')
                              ? Text('')
                              : Text(
                                  l10n.l_name_already_exists,
                                  style: TextStyle(color: Colors.red),
                                )
                        ]),
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
            )));
  }

  bool isUnique(String nameText, String? issuerText) {
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
    checkedCreds.forEach((k, v) => v ? credsToAdd++ : null);
    if (numCreds! + credsToAdd <= 32) return true;
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
      await _doAddCredential(devicePath: devicePath, credUri: cred.toUri());
    } else if (isAndroid) {
      // Send the credential to Android to be added to the next YubiKey
      await _doAddCredential(devicePath: null, credUri: cred.toUri());
    }
  }

  Future<void> _doAddCredential(
      {DevicePath? devicePath, required Uri credUri}) async {
    try {
      if (devicePath == null) {
        assert(isAndroid, 'devicePath is only optional for Android');
        await ref.read(addCredentialToAnyProvider).call(credUri);
      } else {
        await ref
            .read(credentialListProvider(devicePath).notifier)
            .addAccount(credUri);
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
