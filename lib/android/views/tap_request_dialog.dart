import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/android/api/impl.dart';

import '../../app/navigation_service.dart';

class FDialogApiImpl extends FDialogApi {
  static _TapRequestDialogState? dialogState;

  @override
  Future<void> closeDialogApi() async {
    await dialogState?.close();
    dialogState = null;
  }

  @override
  Future<void> showDialogApi(String dialogParametersJson) async {
    var dialogParameters = jsonDecode(dialogParametersJson);
    var message = dialogParameters['message'] ?? 'Missing message parameter';

    /// note about use of unawaited
    /// we don't need the result of the dialog and we don't want show to block
    unawaited(showDialog(
        context: NavigationService.navigatorKey.currentContext!,
        builder: (context) => TapRequestDialog(
              message,
            )));
  }
}

class TapRequestDialog extends ConsumerStatefulWidget {
  /// the current operation he user is performing
  final String message;

  const TapRequestDialog(this.message, {Key? key}) : super(key: key);

  static void initialize() {
    FDialogApi.setup(FDialogApiImpl());
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TapRequestDialogState();
}

class _TapRequestDialogState extends ConsumerState<TapRequestDialog> {
  /// used for information in the dialog (Success/Failure)
  String _resultMessage = '';

  /// mutable icon in the dialog, changes based on the operation result
  IconData _icon = Icons.nfc;

  bool _canPop = true;
  bool _userCancelled = false;

  _TapRequestDialogState();

  @override
  void initState() {
    super.initState();
    _canPop = true;
    FDialogApiImpl.dialogState = this;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> close() async {
    if (_userCancelled) {
      return;
    }

    if (mounted) {
      setState(() {
        _icon = Icons.check_circle;
        _resultMessage = 'Success';
        _canPop = false; // we will close after delay, forbid manual closing
      });

      await Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          var dialogContext = NavigationService.navigatorKey.currentContext!;
          Navigator.pop(dialogContext);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          setState(() {
            _userCancelled = true;
          });
          HDialogApi _api = HDialogApi();
          await _api.dialogClosed();
          return _canPop;
        },
        child: AlertDialog(
          title: const Text('Tap your key'),
          content: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Operation: ${widget.message}'),
                  const SizedBox(
                    height: 32,
                  ),
                  Icon(
                    _icon,
                    size: 64,
                  ),
                  _resultMessage.isNotEmpty
                      ? Text(
                          _resultMessage,
                        )
                      : const SizedBox(
                          height: 0,
                        ),
                ],
              )),
        ));
  }
}
