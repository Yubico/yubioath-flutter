import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../management/models.dart';
import '../state.dart';
import 'locked_page.dart';
import 'unlocked_page.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          loading: () => AppPage(
                title: Text(AppLocalizations.of(context)!.fido_webauthn),
                centered: true,
                child: const AppLoadingScreen(),
              ),
          error: (error, _) {
            final supported = deviceData
                    .info.supportedCapabilities[deviceData.node.transport] ??
                0;
            if (Capability.fido2.value & supported == 0) {
              return MessagePage(
                title: Text(AppLocalizations.of(context)!.fido_webauthn),
                graphic: manageAccounts,
                header: AppLocalizations.of(context)!.fido_ready_to_use,
                message: AppLocalizations.of(context)!.fido_register_as_a_key,
              );
            }
            final enabled = deviceData.info.config
                    .enabledCapabilities[deviceData.node.transport] ??
                0;
            if (Capability.fido2.value & enabled == 0) {
              return MessagePage(
                title: Text(AppLocalizations.of(context)!.fido_webauthn),
                header: AppLocalizations.of(context)!.fido_fido_disabled,
                message: AppLocalizations.of(context)!.fido_webauthn_req_fido,
              );
            }

            return AppFailurePage(
              title: Text(AppLocalizations.of(context)!.fido_webauthn),
              cause: error,
            );
          },
          data: (fidoState) {
            return fidoState.unlocked
                ? FidoUnlockedPage(deviceData.node, fidoState)
                : FidoLockedPage(deviceData.node, fidoState);
          });
}
