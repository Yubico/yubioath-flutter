import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/views/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class RenameFingerprintDialog extends ConsumerStatefulWidget {
  final DeviceNode device;
  final Fingerprint fingerprint;
  const RenameFingerprintDialog(this.device, this.fingerprint, {Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RenameAccountDialogState();
}

class _RenameAccountDialogState extends ConsumerState<RenameFingerprintDialog> {
  late String _label;
  _RenameAccountDialogState();

  @override
  void initState() {
    super.initState();
    _label = widget.fingerprint.label ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    final fingerprint = widget.fingerprint;
    final label = fingerprint.label ?? 'Unnamed (ID: ${fingerprint.id})';

    return ResponsiveDialog(
      title: const Text('Rename fingerprint'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rename $label?'),
          const Text('This will change the label of the fingerprint.'),
          TextFormField(
            initialValue: _label,
            maxLength: 15,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Label',
            ),
            onChanged: (value) {
              setState(() {
                _label = value.trim();
              });
            },
          ),
        ]
            .map((e) => Padding(
                  child: e,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: _label.isNotEmpty
              ? () async {
                  final renamed = await ref
                      .read(fingerprintProvider(widget.device.path).notifier)
                      .renameFingerprint(fingerprint, _label);
                  Navigator.of(context).pop(renamed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fingerprint renamed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
