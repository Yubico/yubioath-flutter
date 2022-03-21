import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../core/models.dart';
import '../state.dart';
import '../../app/views/responsive_dialog.dart';
import '../../fido/models.dart';
import '../../app/models.dart';
import '../../app/state.dart';

final _log = Logger('fido.views.reset_dialog');

class ResetDialog extends ConsumerStatefulWidget {
  final DeviceNode node;
  const ResetDialog(this.node, {Key? key}) : super(key: key);

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
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      // Prevent over-popping if reset causes currentDevice to change.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    return ResponsiveDialog(
      title: const Text('Factory reset'),
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
                style: Theme.of(context).textTheme.headline6),
          ),
        ]
            .map((e) => Padding(
                  child: e,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ))
            .toList(),
      ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FIDO application reset'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }, onError: (e) {
                    _log.severe('Error performing FIDO reset', e);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error performing reset'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                }
              : null,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
