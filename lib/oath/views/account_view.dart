/*
 * Copyright (C) 2022-2023 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../widgets/menu_list_tile.dart';
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_helper.dart';
import 'account_icon.dart';
import 'actions.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

class AccountView extends ConsumerStatefulWidget {
  final OathCredential credential;
  const AccountView(this.credential, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  OathCredential get credential => widget.credential;

  final _focusNode = FocusNode();
  int _lastTap = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Color _iconColor(int shade) {
    final colors = [
      Colors.red[shade],
      Colors.pink[shade],
      Colors.purple[shade],
      Colors.deepPurple[shade],
      Colors.indigo[shade],
      Colors.blue[shade],
      Colors.lightBlue[shade],
      Colors.cyan[shade],
      Colors.teal[shade],
      Colors.green[shade],
      Colors.lightGreen[shade],
      Colors.lime[shade],
      Colors.yellow[shade],
      Colors.amber[shade],
      Colors.orange[shade],
      Colors.deepOrange[shade],
      Colors.brown[shade],
      Colors.grey[shade],
      Colors.blueGrey[shade],
    ];

    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return colors[label.hashCode % colors.length]!;
  }

  List<PopupMenuItem> _buildPopupMenu(
      BuildContext context, AccountHelper helper) {
    return helper.buildActions().map((e) {
      final intent = e.intent;
      return buildMenuItem(
        leading: e.icon,
        title: Text(e.text),
        action: intent != null
            ? () {
                Actions.invoke(context, intent);
              }
            : null,
        trailing: e.trailing,
      );
    }).toList();
  }

  String? a11yCredentialLabel(String? issuer, String? name, OathCode? code) {
    String? label = '';
    String? tmpIssuer = issuer;
    String? tmpName = name;
    String? tmpCode = code?.value;
    if (tmpIssuer != null) {
      label += tmpIssuer;
    }
    if (tmpName != null) {
      label += tmpName;
    }
    if (tmpCode != null) {
      label += tmpCode;
    }

    return label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;

    return registerOathActions(
      credential,
      ref: ref,
      actions: {
        OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) async {
          await showBlurDialog(
            context: context,
            builder: (context) => AccountDialog(credential),
          );
          return null;
        }),
        EditIntent: CallbackAction<EditIntent>(onInvoke: (_) async {
          final node = ref.read(currentDeviceProvider)!;
          final credentials = ref.read(credentialsProvider);
          return await ref.read(withContextProvider)(
              (context) async => await showBlurDialog(
                    context: context,
                    builder: (context) =>
                        RenameAccountDialog(node, credential, credentials),
                  ));
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final node = ref.read(currentDeviceProvider)!;
          return await ref.read(withContextProvider)((context) async =>
              await showBlurDialog(
                context: context,
                builder: (context) => DeleteAccountDialog(node, credential),
              ) ??
              false);
        }),
      },
      builder: (context) {
        final helper = AccountHelper(context, ref, credential);
        return GestureDetector(
          onSecondaryTapDown: (details) {
            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                0,
              ),
              items: _buildPopupMenu(context, helper),
            );
          },
          child: LayoutBuilder(builder: (context, constraints) {
            final showAvatar = constraints.maxWidth >= 315;

            final subtitle = helper.subtitle;

            final circleAvatar = CircleAvatar(
              foregroundColor: darkMode ? Colors.black : Colors.white,
              backgroundColor: _iconColor(darkMode ? 300 : 400),
              child: Text(
                (credential.issuer ?? credential.name)
                    .characters
                    .first
                    .toUpperCase(),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
              ),
            );

            return Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.enter): const OpenIntent(),
                  LogicalKeySet(LogicalKeyboardKey.space): const OpenIntent(),
                },
                child: Semantics(
                  label: a11yCredentialLabel(
                      credential.issuer, credential.name, helper.code),
                  child: ListTile(
                    focusNode: _focusNode,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    onTap: () {
                      if (isDesktop) {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        if (now - _lastTap < 500) {
                          setState(() {
                            _lastTap = 0;
                          });
                          Actions.maybeInvoke(context, const CopyIntent());
                        } else {
                          _focusNode.requestFocus();
                          setState(() {
                            _lastTap = now;
                          });
                        }
                      } else {
                        Actions.maybeInvoke<OpenIntent>(
                            context, const OpenIntent());
                      }
                    },
                    onLongPress: () {
                      Actions.maybeInvoke(context, const CopyIntent());
                    },
                    leading: showAvatar
                        ? AccountIcon(
                            issuer: credential.issuer,
                            defaultWidget: circleAvatar)
                        : null,
                    title: Text(
                      helper.title,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                    ),
                    subtitle: subtitle != null
                        ? Text(
                            subtitle,
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                          )
                        : null,
                    trailing: Focus(
                      skipTraversal: true,
                      descendantsAreTraversable: false,
                      child: helper.code != null
                          ? FilledButton.tonalIcon(
                              icon: helper.buildCodeIcon(),
                              label: helper.buildCodeLabel(),
                              onPressed: () {
                                Actions.maybeInvoke<OpenIntent>(
                                    context, const OpenIntent());
                              },
                            )
                          : FilledButton.tonal(
                              onPressed: () {
                                Actions.maybeInvoke<OpenIntent>(
                                    context, const OpenIntent());
                              },
                              child: helper.buildCodeIcon()),
                    ),
                  ),
                ));
          }),
        );
      },
    );
  }
}
