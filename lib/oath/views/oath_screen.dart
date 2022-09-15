import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../widgets/menu_list_tile.dart';
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'account_list.dart';
import 'add_account_page.dart';
import 'manage_password_dialog.dart';
import 'reset_dialog.dart';
import 'unlock_form.dart';

class OathScreen extends ConsumerWidget {
  final DevicePath devicePath;
  const OathScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(oathStateProvider(devicePath)).when(
          loading: () => AppPage(
            title: Text(AppLocalizations.of(context)!.oath_authenticator),
            centered: true,
            child: const AppLoadingScreen(),
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
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
        title: Text(AppLocalizations.of(context)!.oath_authenticator),
        keyActions: [
          buildMenuItem(
            title: Text(AppLocalizations.of(context)!.oath_manage_password,
                key: keys.setOrManagePasswordAction),
            leading: const Icon(Icons.password),
            action: () {
              showBlurDialog(
                context: context,
                builder: (context) =>
                    ManagePasswordDialog(devicePath, oathState),
              );
            },
          ),
          buildMenuItem(
            title: Text(AppLocalizations.of(context)!.oath_reset_oath),
            leading: const Icon(Icons.delete),
            action: () {
              showBlurDialog(
                context: context,
                builder: (context) => ResetDialog(devicePath),
              );
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: UnlockForm(
            devicePath,
            keystore: oathState.keystore,
          ),
        ),
      );
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
    final credentials = ref.watch(credentialsProvider);
    if (credentials?.isEmpty == true) {
      return MessagePage(
        title: Text(AppLocalizations.of(context)!.oath_authenticator),
        key: keys.noAccountsView,
        graphic: noAccounts,
        header: AppLocalizations.of(context)!.oath_no_accounts,
        keyActions: _buildActions(
          context,
          credentials: null,
        ),
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
              style: textTheme.subtitle1
                  ?.copyWith(fontSize: textTheme.titleSmall?.fontSize),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.oath_search_accounts,
                isDense: true,
                prefixIcon: const Icon(Icons.search_outlined),
                prefixIconConstraints: const BoxConstraints(
                  minHeight: 30,
                  minWidth: 30,
                ),
                border: InputBorder.none,
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
        keyActions: _buildActions(
          context,
          credentials: credentials,
        ),
        child: AccountList(widget.devicePath, widget.oathState),
      ),
    );
  }

  List<PopupMenuEntry> _buildActions(
    BuildContext context, {
    required List<OathCredential>? credentials,
  }) {
    final used = credentials?.length ?? 0;
    final capacity = widget.oathState.version.isAtLeast(4) ? 32 : null;
    return [
      buildMenuItem(
        title: Text(
          AppLocalizations.of(context)!.oath_add_account,
          key: keys.addAccountAction,
        ),
        leading: const Icon(Icons.person_add_alt_1),
        trailing: capacity != null ? '$used/$capacity' : null,
        action: capacity == null || capacity > used
            ? () async {
                CredentialData? otpauth;
                if (Platform.isAndroid) {
                  final scanner = ref.read(qrScannerProvider);
                  if (scanner != null) {
                    final url = await scanner.scanQr();
                    if (url != null) {
                      otpauth = CredentialData.fromUri(Uri.parse(url));
                    }
                  }
                }
                await showBlurDialog(
                  context: context,
                  builder: (context) => OathAddAccountPage(
                    widget.devicePath,
                    widget.oathState,
                    credentials: credentials,
                    credentialData: otpauth,
                  ),
                );
              }
            : null,
      ),
      buildMenuItem(
          title: Text(
              widget.oathState.hasKey
                  ? AppLocalizations.of(context)!.oath_manage_password
                  : AppLocalizations.of(context)!.oath_set_password,
              key: keys.setOrManagePasswordAction),
          leading: const Icon(Icons.password),
          action: () {
            showBlurDialog(
              context: context,
              builder: (context) =>
                  ManagePasswordDialog(widget.devicePath, widget.oathState),
            );
          }),
      buildMenuItem(
          title: Text(AppLocalizations.of(context)!.oath_reset_oath,
              key: keys.resetAction),
          leading: const Icon(Icons.delete),
          action: () {
            showBlurDialog(
              context: context,
              builder: (context) => ResetDialog(widget.devicePath),
            );
          }),
    ];
  }
}
