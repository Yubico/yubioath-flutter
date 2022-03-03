import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/circle_timer.dart';
import '../models.dart';
import 'account_mixin.dart';

class AccountDialog extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;
  const AccountDialog(this.credential, {Key? key}) : super(key: key);

  @override
  Future<OathCredential?> renameCredential(
      BuildContext context, WidgetRef ref) async {
    final renamed = await super.renameCredential(context, ref);
    if (renamed != null) {
      // Replace this dialog with a new one, for the renamed credential.
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) {
          return AccountDialog(renamed);
        },
      );
    }
    return renamed;
  }

  @override
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final deleted = await super.deleteCredential(context, ref);
    if (deleted) {
      Navigator.of(context).pop();
    }
    return deleted;
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    return buildActions(ref).map((e) {
      final action = e.action;
      return IconButton(
        icon: e.icon,
        tooltip: e.text,
        onPressed: action != null
            ? () {
                action(context);
              }
            : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = getCode(ref);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        insetPadding: const EdgeInsets.all(0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            actions: _buildActions(context, ref),
          ),
          body: LayoutBuilder(builder: (context, constraints) {
            return ListView(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: GestureDetector(
                      onTap: () {}, // Blocks parent detector GestureDetector
                      child: Material(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        elevation: 16.0,
                        child: SizedBox(
                          width: 320,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 12.0),
                            child: Column(
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatCode(ref),
                                    softWrap: false,
                                    style: isExpired(ref)
                                        ? Theme.of(context)
                                            .textTheme
                                            .headline2
                                            ?.copyWith(color: Colors.grey)
                                        : Theme.of(context).textTheme.headline2,
                                  ),
                                ),
                                Text(label),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox.square(
                                    dimension: 16,
                                    child: code != null
                                        ? CircleTimer(
                                            code.validFrom * 1000,
                                            code.validTo * 1000,
                                          )
                                        : null,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
