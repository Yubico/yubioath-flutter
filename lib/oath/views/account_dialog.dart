import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../widgets/circle_timer.dart';
import '../models.dart';
import '../state.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';
import 'utils.dart';

class AccountDialog extends ConsumerWidget {
  final DeviceNode device;
  final OathCredential credential;
  const AccountDialog(this.device, this.credential, {Key? key})
      : super(key: key);

  List<Widget> _buildActions(BuildContext context, WidgetRef ref,
      OathCode? code, bool expired, bool favorite) {
    final manual =
        credential.touchRequired || credential.oathType == OathType.hotp;
    final ready = expired || credential.oathType == OathType.hotp;

    return [
      if (manual)
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Calculate',
          onPressed: ready
              ? () {
                  calculateCode(
                    context,
                    credential,
                    ref.read(credentialListProvider(device.path).notifier),
                  );
                }
              : null,
        ),
      IconButton(
        icon: const Icon(Icons.copy),
        tooltip: 'Copy to clipboard',
        onPressed: code == null || expired
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: code.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
      ),
      IconButton(
        icon: Icon(favorite ? Icons.star : Icons.star_border),
        tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
        onPressed: () {
          ref.read(favoritesProvider.notifier).toggleFavorite(credential.id);
        },
      ),
      IconButton(
        icon: const Icon(Icons.edit),
        tooltip: 'Rename account',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => RenameAccountDialog(device, credential),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_forever),
        tooltip: 'Delete account',
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => DeleteAccountDialog(device, credential),
          );
          if (result) {
            Navigator.of(context).pop();
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    final code = ref.watch(codeProvider(credential));
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    final favorite = ref.watch(favoritesProvider).contains(credential.id);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      insetPadding: const EdgeInsets.all(0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: _buildActions(context, ref, code, expired, favorite),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return ListView(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: GestureDetector(
                    onTap: () {}, // Blocks parent detector GestureDetector
                    child: Material(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      elevation: 16.0,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            children: [
                              Text(
                                formatOathCode(code),
                                style: expired
                                    ? Theme.of(context)
                                        .textTheme
                                        .headline2
                                        ?.copyWith(color: Colors.grey)
                                    : Theme.of(context).textTheme.headline2,
                              ),
                              Text(label),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox.square(
                                  dimension: 16,
                                  child: code != null
                                      ? CircleTimer(
                                          code.validFrom * 1000,
                                          code.validTo * 1000,
                                        )
                                      : null,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
