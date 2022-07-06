import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';

class RenameFingerprintDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const RenameFingerprintDialog(this.devicePath, this.fingerprint, {super.key});

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
    try {
      final renamed = await ref
          .read(fingerprintProvider(widget.devicePath).notifier)
          .renameFingerprint(widget.fingerprint, _label);
      if (!mounted) return;
      Navigator.of(context).pop(renamed);
      showMessage(context, 'Fingerprint renamed');
    } catch (e) {
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        'Error renaming: $errorMessage',
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            inputFormatters: [limitBytesLength(15)],
            buildCounter: buildByteCounterFor(_label),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Label',
              prefixIcon: Icon(Icons.fingerprint_outlined),
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
