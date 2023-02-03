/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../models.dart';
import 'account_mixin.dart';

class AccountDialog extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;

  const AccountDialog(this.credential, {super.key});

  @override
  Future<OathCredential?> renameCredential(
      BuildContext context, WidgetRef ref) async {
    final renamed = await super.renameCredential(context, ref);
    if (renamed != null) {
      // Replace this dialog with a new one, for the renamed credential.
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        await showBlurDialog(
          context: context,
          builder: (context) {
            return AccountDialog(renamed);
          },
        );
      });
    }
    return renamed;
  }

  @override
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final deleted = await super.deleteCredential(context, ref);
    if (deleted) {
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
      });
    }
    return deleted;
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final actions = buildActions(context, ref);

    final theme = Theme.of(context).colorScheme;

    final copy = actions.firstWhere(((e) => e.text.startsWith('Copy')));
    final delete = actions.firstWhere(((e) => e.text.startsWith('Delete')));
    final colors = {
      copy: Pair(theme.primary, theme.onPrimary),
      delete: Pair(theme.error, theme.onError),
    };

    // If we can't copy, but can calculate, highlight that button instead
    if (copy.action == null) {
      final calculates = actions.where(((e) => e.text.startsWith('Calculate')));
      if (calculates.isNotEmpty) {
        colors[calculates.first] = Pair(theme.primary, theme.onPrimary);
      }
    }

    return actions.map((e) {
      final action = e.action;
      final color = colors[e] ?? Pair(theme.secondary, theme.onSecondary);
      final tooltip = e.trailing != null ? '${e.text}\n${e.trailing}' : e.text;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: CircleAvatar(
          backgroundColor: action != null ? color.first : theme.secondary,
          foregroundColor: color.second,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: action != null ? color.first : theme.secondary,
              foregroundColor: color.second,
              disabledBackgroundColor: theme.onSecondary.withOpacity(0.2),
              fixedSize: const Size.square(38),
            ),
            icon: e.icon,
            iconSize: 22,
            tooltip: tooltip,
            onPressed: action != null
                ? () {
                    action(context);
                  }
                : null,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final currentDeviceData = ref.watch(currentDeviceDataProvider);
    if (currentDeviceData is! AsyncData) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final code = getCode(ref);
    if (isValid(ref) && code == null) {
      if (isDesktop ||
          (isAndroid &&
              currentDeviceData.value?.node.transport == Transport.usb)) {
        Timer(Duration.zero, () => calculateCode(context, ref));
      }
    }
    return Actions(
      actions: {
        CopyIntent: CallbackAction(onInvoke: (_) async {
          if (isExpired(code, ref)) {
            await calculateCode(context, ref);
          }
          await ref.read(withContextProvider)(
            (context) async {
              copyToClipboard(
                  ref.watch(clipboardProvider), context, getCode(ref));
            },
          );
          return null;
        }),
      },
      child: FocusScope(
        autofocus: true,
        child: AlertDialog(
          title: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle != null)
                Text(
                  subtitle!,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  // This is what ListTile uses for subtitle
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).textTheme.bodySmall!.color,
                      ),
                ),
              const SizedBox(height: 12.0),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                ),
                child: Center(
                  child: FittedBox(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 28),
                      child: IconTheme(
                        data: IconTheme.of(context).copyWith(size: 24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: buildCodeView(ref),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(vertical: 10.0),
          actions: [
            Center(
              child: FittedBox(
                alignment: Alignment.center,
                child: Row(children: _buildActions(context, ref)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
