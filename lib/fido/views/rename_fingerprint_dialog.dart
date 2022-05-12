import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class RenameFingerprintDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const RenameFingerprintDialog(this.devicePath, this.fingerprint, {Key? key})
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
    _label = widget.fingerprint.name ?? '';
  }

  _submit() async {
    final renamed = await ref
        .read(fingerprintProvider(widget.devicePath).notifier)
        .renameFingerprint(widget.fingerprint, _label);
    if (!mounted) return;
    Navigator.of(context).pop(renamed);
    showMessage(context, 'Fingerprint renamed');
  }

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    return ResponsiveDialog(
      title: const Text('Rename fingerprint'),
      actions: [
        TextButton(
          onPressed: _label.isNotEmpty ? _submit : null,
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rename ${widget.fingerprint.label}?'),
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
            onFieldSubmitted: (_) {
              if (_label.isNotEmpty) {
                _submit();
              }
            },
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
