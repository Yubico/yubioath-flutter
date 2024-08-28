import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/models.dart';
import '../../state.dart';

final nfcActivityCommandNotifier = NotifierProvider<
    _NfcActivityWidgetCommandNotifier,
    NfcActivityWidgetCommand>(_NfcActivityWidgetCommandNotifier.new);

class _NfcActivityWidgetCommandNotifier
    extends Notifier<NfcActivityWidgetCommand> {
  @override
  NfcActivityWidgetCommand build() {
    return NfcActivityWidgetCommand(action: const NfcActivityWidgetAction());
  }

  void update(NfcActivityWidgetCommand command) {
    state = command;
  }
}

final nfcActivityWidgetNotifier =
    NotifierProvider<_NfcActivityWidgetNotifier, NfcActivityWidgetState>(
        _NfcActivityWidgetNotifier.new);

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
    ref.read(nfcActivityCommandNotifier.notifier).update(
        NfcActivityWidgetCommand(
            action: const NfcActivityWidgetActionHideWidget(timeoutMs: 0)));
  }
}

class _NfcActivityWidgetNotifier extends Notifier<NfcActivityWidgetState> {
  @override
  NfcActivityWidgetState build() {
    return NfcActivityWidgetState(isShowing: false, child: const SizedBox());
  }

  void update(Widget child) {
    state = state.copyWith(child: child);
  }

  void setShowing(bool value) {
    state = state.copyWith(isShowing: value);
  }

  void setDialogProperties(
      {String? operationName,
      String? operationProcessing,
      String? operationSuccess,
      String? operationFailure,
      bool? showSuccess}) {
    state = state.copyWith(
        operationName: operationName,
        operationProcessing: operationProcessing,
        operationSuccess: operationSuccess,
        operationFailure: operationFailure,
        showSuccess: showSuccess);
  }
}

class NfcBottomSheet extends ConsumerWidget {
  const NfcBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widget = ref.watch(nfcActivityWidgetNotifier.select((s) => s.child));
    final showCloseButton = ref.watch(
        nfcActivityWidgetNotifier.select((s) => s.showCloseButton ?? false));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCloseButton) const SizedBox(height: 8),
        if (showCloseButton)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close, fill: 1, size: 24))
              ],
            ),
          ),
        if (showCloseButton) const SizedBox(height: 16),
        if (!showCloseButton) const SizedBox(height: 48),
        widget,
        const SizedBox(height: 32),
      ],
    );
  }
}
