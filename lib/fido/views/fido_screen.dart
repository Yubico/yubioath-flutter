import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../desktop/state.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'fingerprint_page.dart';
import 'main_page.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          none: () => const AppLoadingScreen(),
          failure: (reason) {
            final supported = deviceData
                .info.supportedCapabilities[deviceData.node.transport]!;
            if (Capability.fido2.value & supported == 0) {
              return const AppFailureScreen(
                  'WebAuthn is supported by this device, but there are no management options available.');
            }
            if (Platform.isWindows) {
              if (!ref
                  .watch(rpcStateProvider.select((state) => state.isAdmin))) {
                return const AppFailureScreen(
                    'WebAuthn management requires elevated privileges.\nRestart this app as administrator.');
              }
            }
            return AppFailureScreen(reason);
          },
          success: (state) => _SubPageHolder(deviceData.node, state));
}

class _SubPageHolder extends StatefulWidget {
  final DeviceNode node;
  final FidoState state;

  const _SubPageHolder(this.node, this.state, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubPageHolderState();
}

class _SubPageHolderState extends State<_SubPageHolder> {
  SubPage _subpage = SubPage.main;

  void setSubPage(SubPage page) {
    setState(() {
      _subpage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_subpage) {
      case SubPage.fingerprints:
        return FingerprintPage(widget.node, widget.state);
      default:
        return FidoMainPage(
          widget.node,
          widget.state,
          setSubPage: setSubPage,
        );
    }
  }
}
