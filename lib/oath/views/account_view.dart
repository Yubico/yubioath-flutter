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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/circle_timer.dart';
import '../../widgets/menu_list_tile.dart';
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_mixin.dart';

class AccountView extends ConsumerStatefulWidget {
  final OathCredential credential;
  const AccountView(this.credential, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> with AccountMixin {
  @override
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
    return colors[label.hashCode % colors.length]!;
  }

  List<PopupMenuItem> _buildPopupMenu(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      return buildMenuItem(
        leading: e.icon,
        title: Text(e.text),
        action: action != null
            ? () {
                ref.read(withContextProvider)((context) async {
                  action.call(context);
                });
              }
            : null,
        trailing: e.trailing,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final code = getCode(ref);
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    final calculateReady = code == null ||
        credential.oathType == OathType.hotp ||
        (credential.touchRequired && expired);

    Future<void> triggerCopy() async {
      try {
        final withContext = ref.read(withContextProvider);
        await withContext(
          (context) async {
            OathCode? code = calculateReady
                ? await calculateCode(
                    context,
                    ref,
                  )
                : getCode(ref);
            await withContext((context) async =>
                copyToClipboard(ref.watch(clipboardProvider), context, code));
          },
        );
      } on CancellationException catch (_) {
        // ignored
      }
    }

    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;

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
          items: _buildPopupMenu(context, ref),
        );
      },
      child: Actions(
        actions: {
          CopyIntent: CallbackAction<CopyIntent>(onInvoke: (_) async {
            await triggerCopy();
            return null;
          }),
          OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) async {
            await showBlurDialog(
              context: context,
              builder: (context) => AccountDialog(credential),
            );
            return null;
          }),
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final showAvatar = constraints.maxWidth >= 315;

          return Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.enter): const OpenIntent(),
              LogicalKeySet(LogicalKeyboardKey.space): const OpenIntent(),
            },
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
                    triggerCopy();
                  } else {
                    _focusNode.requestFocus();
                    setState(() {
                      _lastTap = now;
                    });
                  }
                } else {
                  Actions.maybeInvoke<OpenIntent>(context, const OpenIntent());
                }
              },
              onLongPress: triggerCopy,
              leading: showAvatar
                  ? CircleAvatar(
                      foregroundColor: darkMode ? Colors.black : Colors.white,
                      backgroundColor: _iconColor(darkMode ? 300 : 400),
                      child: Text(
                        (credential.issuer ?? credential.name)
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w300),
                      ),
                    )
                  : null,
              title: Text(
                title,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle!,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                    )
                  : null,
              trailing: Focus(
                skipTraversal: true,
                descendantsAreTraversable: false,
                child: FilledButton.tonalIcon(
                  icon: AnimatedSize(
                    alignment: Alignment.centerRight,
                    duration: const Duration(milliseconds: 100),
                    child: Opacity(
                      opacity: 0.4,
                      child: (credential.oathType == OathType.hotp
                              ? (expired ? const Icon(Icons.refresh) : null)
                              : (expired
                                  ? (credential.touchRequired
                                      ? const Icon(Icons.touch_app)
                                      : null)
                                  : SizedBox.square(
                                      dimension:
                                          (IconTheme.of(context).size ?? 18) *
                                              0.8,
                                      child: CircleTimer(
                                        code.validFrom * 1000,
                                        code.validTo * 1000,
                                      ),
                                    ))) ??
                          const SizedBox(),
                    ),
                  ),
                  label: Opacity(
                    opacity: expired ? 0.4 : 1.0,
                    child: Text(
                      formatCode(code),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        //fontWeight: FontWeight.w400,
                      ),
                      textHeightBehavior: TextHeightBehavior(
                        // This helps with vertical centering on desktop
                        applyHeightToFirstAscent: !isDesktop,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Actions.maybeInvoke<OpenIntent>(
                        context, const OpenIntent());
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
