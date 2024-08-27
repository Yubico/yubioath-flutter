/*
 * Copyright (C) 2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/message.dart';
import '../../app/state.dart';
import '../../widgets/file_drop_overlay.dart';
import '../../widgets/file_drop_target.dart';
import '../../widgets/responsive_dialog.dart';
import 'icon_pack.dart';
import 'icon_pack_manager.dart';

class IconPackDialog extends ConsumerWidget {
  const IconPackDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final iconPack = ref.watch(iconPackProvider);
    return FileDropTarget(
        onFileDropped: (file) async {
          final importStatus = await ref
              .read(iconPackProvider.notifier)
              .importPack(l10n, file.path);
          await ref.read(withContextProvider)((context) async {
            if (importStatus) {
              showMessage(context, l10n.l_icon_pack_imported);
            } else {
              showMessage(
                  context,
                  l10n.l_import_icon_pack_failed(
                      ref.read(iconPackProvider.notifier).lastError ??
                          l10n.l_import_error));
            }
          });
        },
        overlay: FileDropOverlay(
          title: iconPack.when(
              data: (IconPack? data) => data != null
                  ? l10n.s_replace_icon_pack
                  : l10n.s_load_icon_pack,
              error: (Object error, StackTrace stackTrace) =>
                  l10n.s_load_icon_pack,
              loading: () => null),
        ),
        child: ResponsiveDialog(
          title: Text(l10n.s_custom_icons),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogDescription(),
                const SizedBox(height: 4),
                _action(iconPack, l10n),
                _loadedIconPackRow(iconPack),
              ]
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: e,
                      ))
                  .toList(),
            ),
          ),
        ));
  }

  Widget? _loadedIconPackRow(AsyncValue<IconPack?> iconPack) {
    return iconPack.when(
        data: (IconPack? data) =>
            (data != null) ? _IconPackDescription(data) : null,
        error: (Object error, StackTrace stackTrace) => null,
        loading: () => const Padding(
              // Add extra padding to have same size as _IconPackDescription
              padding: EdgeInsets.symmetric(vertical: 18.0),
              child: LinearProgressIndicator(),
            ));
  }

  Widget? _action(AsyncValue<IconPack?> iconPack, AppLocalizations l10n) =>
      iconPack.when(
          data: (IconPack? data) => _ImportActionChip(
              data != null ? l10n.s_replace_icon_pack : l10n.s_load_icon_pack),
          error: (Object error, StackTrace stackTrace) =>
              _ImportActionChip(l10n.s_load_icon_pack),
          loading: () => _ImportActionChip(
                l10n.l_loading_icon_pack,
                disabled: true,
              ));
}

class _DialogDescription extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        text: l10n.p_custom_icons_description,
        style: theme.textTheme.bodyMedium,
        children: [const TextSpan(text: ' '), _createLearnMoreLink(context)],
      ),
    );
  }

  Uri get _learnMoreUri =>
      Uri.parse('https://yubi.co/ya-custom-account-icons-doc');

  TextSpan _createLearnMoreLink(BuildContext context) {
    final theme = Theme.of(context);
    return TextSpan(
      text: AppLocalizations.of(context)!.s_learn_more,
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.primary),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          await launchUrl(_learnMoreUri, mode: LaunchMode.externalApplication);
        },
      children: const [
        TextSpan(text: ' ') // without this the recognizer takes over whole row
      ],
    );
  }
}

class _IconPackDescription extends ConsumerWidget {
  final IconPack iconPack;

  const _IconPackDescription(this.iconPack);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
              fit: FlexFit.loose,
              child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                      text: iconPack.name,
                      style: theme.textTheme.bodyMedium,
                      children: [TextSpan(text: ' (${iconPack.version})')]))),
          Row(
            children: [
              IconButton(
                  tooltip: l10n.s_remove_icon_pack,
                  onPressed: () async {
                    final removePackStatus =
                        await ref.read(iconPackProvider.notifier).removePack();
                    await ref.read(withContextProvider)(
                      (context) async {
                        if (removePackStatus) {
                          showMessage(context, l10n.l_icon_pack_removed);
                        } else {
                          showMessage(context, l10n.l_remove_icon_pack_failed);
                        }
                      },
                    );
                  },
                  icon: const Icon(
                    Symbols.delete,
                    size: 20.0,
                  )),
            ],
          )
        ]);
  }
}

class _ImportActionChip extends ConsumerWidget {
  final String _label;
  final bool disabled;

  const _ImportActionChip(this._label, {this.disabled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
        onPressed: !disabled
            ? () async {
                _importAction(context, ref);
              }
            : null,
        avatar: const Icon(
          Symbols.download,
        ),
        label: Text(_label));
  }

  void _importAction(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['zip'],
        type: FileType.custom,
        allowMultiple: false,
        lockParentWindow: true,
        dialogTitle: l10n.s_choose_icon_pack);
    if (result != null && result.files.isNotEmpty) {
      final importStatus = await ref
          .read(iconPackProvider.notifier)
          .importPack(l10n, result.paths.first!);
      await ref.read(withContextProvider)((context) async {
        if (importStatus) {
          showMessage(context, l10n.l_icon_pack_imported);
        } else {
          showMessage(
              context,
              l10n.l_import_icon_pack_failed(
                  ref.read(iconPackProvider.notifier).lastError ??
                      l10n.l_import_error));
        }
      });
    }
  }
}
