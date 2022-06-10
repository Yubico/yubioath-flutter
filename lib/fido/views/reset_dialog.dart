import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/message.dart';
import '../../core/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../../fido/models.dart';
import '../../app/models.dart';

final _log = Logger('fido.views.reset_dialog');

class ResetDialog extends ConsumerStatefulWidget {
  final DeviceNode node;
  const ResetDialog(this.node, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ResetDialogState();
}

class _ResetDialogState extends ConsumerState<ResetDialog> {
  StreamSubscription<InteractionEvent>? _subscription;
  InteractionEvent? _interaction;

  String _getMessage() {
    final nfc = widget.node.transport == Transport.nfc;
    switch (_interaction) {
      case InteractionEvent.remove:
        return nfc
            ? 'Remove your YubiKey from the NFC reader'
            : 'Unplug your YubiKey';
      case InteractionEvent.insert:
        return nfc
            ? 'Place your YubiKey back on the reader'
            : 'Re-insert your YubiKey';
      case InteractionEvent.touch:
        return 'Touch your YubiKey now';
      case null:
        return 'Press reset to begin...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: const Text('Factory reset'),
      onCancel: () {
        _subscription?.cancel();
      },
      actions: [
        TextButton(
          onPressed: _subscription == null
              ? () async {
                  _subscription = ref
                      .read(fidoStateProvider(widget.node.path).notifier)
                      .reset()
                      .listen((event) {
                    setState(() {
                      _interaction = event;
                    });
                  }, onDone: () {
                    _subscription = null;
                    Navigator.of(context).pop();
                    showMessage(context, 'FIDO application reset');
                  }, onError: (e) {
                    _log.error('Error performing FIDO reset', e);
                    Navigator.of(context).pop();
                    showMessage(context, 'Error performing reset');
                  });
                }
              : null,
          child: const Text('Reset'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Warning! This will irrevocably delete all U2F and FIDO2 accounts from your YubiKey.'),
          Text(
            'Your credentials, as well as any PIN set, will be removed from this YubiKey. Make sure to first disable these from their respective web sites to avoid being locked out of your accounts.',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Center(
            child: Text(_getMessage(),
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList(),
      ),
    );
  }
}
