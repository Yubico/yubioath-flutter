import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../state.dart';
import 'models.dart';

final nfcEventCommandNotifier =
    NotifierProvider<_NfcEventCommandNotifier, NfcEventCommand>(
        _NfcEventCommandNotifier.new);

class _NfcEventCommandNotifier extends Notifier<NfcEventCommand> {
  @override
  NfcEventCommand build() {
    return NfcEventCommand(event: const NfcEvent());
  }

  void sendCommand(NfcEventCommand command) {
    state = command;
  }
}

final nfcViewNotifier =
    NotifierProvider<_NfcViewNotifier, NfcView>(_NfcViewNotifier.new);

class NfcActivityClosingCountdownWidgetView extends ConsumerStatefulWidget {
  final int closeInSec;
  final Widget child;

  const NfcActivityClosingCountdownWidgetView(
      {super.key, required this.child, this.closeInSec = 3});

  @override
  ConsumerState<NfcActivityClosingCountdownWidgetView> createState() =>
      _NfcActivityClosingCountdownWidgetViewState();
}

class _NfcActivityClosingCountdownWidgetViewState
    extends ConsumerState<NfcActivityClosingCountdownWidgetView> {
  late int counter;
  late Timer? timer;
  bool shouldHide = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(androidNfcActivityProvider, (previous, current) {
      if (current == NfcActivity.ready) {
        timer?.cancel();
        hideNow();
      }
    });

    return Stack(
      fit: StackFit.loose,
      children: [
        Center(child: widget.child),
        Positioned(
          bottom: 0,
          right: 0,
          child: counter > 0
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Closing in $counter'),
                )
              : const SizedBox(),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    counter = widget.closeInSec;
    timer = Timer(const Duration(seconds: 1), onTimer);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void onTimer() async {
    timer?.cancel();
    setState(() {
      counter--;
    });

    if (counter > 0) {
      timer = Timer(const Duration(seconds: 1), onTimer);
    } else {
      hideNow();
    }
  }

  void hideNow() {
    debugPrint('XXX closing because have to!');
    ref.read(nfcEventCommandNotifier.notifier).sendCommand(
        NfcEventCommand(event: const NfcHideViewEvent(timeoutMs: 0)));
  }
}

class _NfcViewNotifier extends Notifier<NfcView> {
  @override
  NfcView build() {
    return NfcView(isShowing: false, child: const SizedBox());
  }

  void update(Widget child) {
    state = state.copyWith(child: child);
  }

  void setShowing(bool value) {
    state = state.copyWith(isShowing: value);
  }

  void setDialogProperties(
      {String? operationSuccess,
      String? operationFailure,
      bool? showSuccess,
      bool? showCloseButton}) {
    state = state.copyWith(
        operationSuccess: operationSuccess,
        operationFailure: operationFailure,
        showSuccess: showSuccess,
        showCloseButton: showCloseButton);
  }
}

class NfcBottomSheet extends ConsumerWidget {
  const NfcBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widget = ref.watch(nfcViewNotifier.select((s) => s.child));
    final showCloseButton =
        ref.watch(nfcViewNotifier.select((s) => s.showCloseButton ?? false));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(fit: StackFit.passthrough, children: [
          if (showCloseButton)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close, fill: 1, size: 24)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
            child: widget,
          )
        ]),
        const SizedBox(height: 32),
      ],
    );
  }
}
