import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../exception/cancellation_exception.dart';
import '../models.dart';
import '../state.dart';

class CalculateIntent extends Intent {
  const CalculateIntent();
}

class TogglePinIntent extends Intent {
  const TogglePinIntent();
}

Future<OathCode?> _calculateCode(
    OathCredential credential, WidgetRef ref) async {
  final node = ref.read(currentDeviceProvider)!;
  try {
    return await ref
        .read(credentialListProvider(node.path).notifier)
        .calculate(credential);
  } on CancellationException catch (_) {
    return null;
  }
}

Widget registerOathActions(
  OathCredential credential, {
  required WidgetRef ref,
  required Widget Function(BuildContext context) builder,
  Map<Type, Action<Intent>> actions = const {},
}) =>
    Actions(
      actions: {
        CalculateIntent: CallbackAction<CalculateIntent>(onInvoke: (_) {
          return _calculateCode(credential, ref);
        }),
        CopyIntent: CallbackAction<CopyIntent>(onInvoke: (_) async {
          var code = ref.read(codeProvider(credential));
          if (code == null ||
              (credential.oathType == OathType.totp &&
                  ref.read(expiredProvider(code.validTo)))) {
            code = await _calculateCode(credential, ref);
          }
          if (code != null) {
            final clipboard = ref.watch(clipboardProvider);
            await clipboard.setText(code.value, isSensitive: true);
            if (!clipboard.platformGivesFeedback()) {
              await ref.read(withContextProvider)((context) async {
                showMessage(context,
                    AppLocalizations.of(context)!.oath_copied_to_clipboard);
              });
            }
          }
          return code;
        }),
        TogglePinIntent: CallbackAction<TogglePinIntent>(onInvoke: (_) {
          ref.read(favoritesProvider.notifier).toggleFavorite(credential.id);
          return null;
        }),
        ChangeAccountIconIntent: CallbackAction<ChangeAccountIconIntent>(onInvoke: (_) async {
          final result = await FilePicker.platform.pickFiles(
              allowedExtensions: ['jpg', 'png'],
              type: FileType.custom,
              allowMultiple: false,
              lockParentWindow: true,
              dialogTitle: 'Choose custom image');
          if (result != null && result.files.isNotEmpty) {
            final importStatus = await ref
                .read(accountIconProvider)
                .importCustomAccountImage(credential.name, credential.issuer, result.paths.first!);

            await ref.read(withContextProvider)(
                  (context) async {
                if (importStatus) {
                  showMessage(context, 'Custom image imported');
                } else {
                  showMessage(context, 'Error importing custom image');
                }
              },
            );
          }

          return null;
        }),
        ...actions,
      },
      child: Builder(builder: builder),
    );
