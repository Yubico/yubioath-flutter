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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'account_list.dart';
import 'key_actions.dart';
import 'unlock_form.dart';

class OathScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const OathScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ref.watch(oathStateProvider(devicePath)).when(
          loading: () => MessagePage(
            title: Text(AppLocalizations.of(context)!.oath_authenticator),
            graphic: const CircularProgressIndicator(),
            delayedContent: true,
          ),
          error: (error, _) => AppFailurePage(
            title: Text(AppLocalizations.of(context)!.oath_authenticator),
            cause: error,
          ),
          data: (oathState) => oathState.locked
              ? _LockedView(devicePath, oathState)
              : _UnlockedView(devicePath, oathState),
        );
  }
}

class _LockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _LockedView(this.devicePath, this.oathState);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: Text(AppLocalizations.of(context)!.oath_authenticator),
      keyActionsBuilder: (context) =>
          oathBuildActions(context, devicePath, oathState, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: UnlockForm(
          devicePath,
          keystore: oathState.keystore,
        ),
      ),
    );
  }
}

class _UnlockedView extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _UnlockedView(this.devicePath, this.oathState);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UnlockedViewState();
}

class _UnlockedViewState extends ConsumerState<_UnlockedView> {
  late FocusNode searchFocus;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchFocus = FocusNode();
    searchController = TextEditingController(text: ref.read(searchProvider));
  }

  @override
  void dispose() {
    searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ONLY rebuild if the number of credentials changes.
    final numCreds = ref.watch(credentialListProvider(widget.devicePath)
        .select((value) => value?.length));
    if (numCreds == 0) {
      return MessagePage(
        title: Text(AppLocalizations.of(context)!.oath_authenticator),
        key: keys.noAccountsView,
        graphic: noAccounts,
        header: AppLocalizations.of(context)!.oath_no_accounts,
        keyActionsBuilder: (context) => oathBuildActions(
            context, widget.devicePath, widget.oathState, ref,
            used: 0),
      );
    }
    return Actions(
      actions: {
        SearchIntent: CallbackAction(onInvoke: (_) {
          searchController.selection = TextSelection(
              baseOffset: 0, extentOffset: searchController.text.length);
          searchFocus.requestFocus();
          return null;
        }),
      },
      child: AppPage(
        title: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (context) {
            final textTheme = Theme.of(context).textTheme;
            return TextFormField(
              key: keys.searchAccountsField,
              controller: searchController,
              focusNode: searchFocus,
              // Use the default style, but with a smaller font size:
              style: textTheme.titleMedium
                  ?.copyWith(fontSize: textTheme.titleSmall?.fontSize),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.oath_search_accounts,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
                prefixIcon: const Icon(Icons.search_outlined),
                prefixIconConstraints:
                    const BoxConstraints(minHeight: 30, minWidth: 30),
                /*
                suffixIcon: IconButton(
                  icon: const Icon(Icons.highlight_off),
                  iconSize: 16,
                  color: Colors.white54,
                  onPressed: searchController.clear,
                ),
                suffixIconConstraints:
                    const BoxConstraints(minHeight: 30, minWidth: 30),
                    */
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).setFilter(value);
              },
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) {
                Focus.of(context).focusInDirection(TraversalDirection.down);
              },
            );
          }),
        ),
        keyActionsBuilder: (context) => oathBuildActions(
          context,
          widget.devicePath,
          widget.oathState,
          ref,
          used: numCreds ?? 0,
        ),
        centered: numCreds == null,
        delayedContent: numCreds == null,
        child: numCreds != null
            ? Consumer(
                builder: (context, ref, _) {
                  return AccountList(
                    ref.watch(credentialListProvider(widget.devicePath)) ?? [],
                  );
                },
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
