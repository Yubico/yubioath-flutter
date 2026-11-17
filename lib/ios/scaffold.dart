import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app/message.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/app_page.dart';
import '../app/views/device_error_screen.dart';
import '../app/views/message_page.dart';
import '../core/models.dart';
import '../exception/cancellation_exception.dart';
import '../generated/l10n/app_localizations.dart';
import '../home/views/home_message_page.dart';
import '../home/views/home_screen.dart';
import '../management/models.dart';
import '../oath/state.dart';
import '../oath/views/oath_screen.dart';
import 'oath/state.dart';
import 'state.dart';

final _log = Logger('ios.scaffold');

class IOSScaffoldPage extends ConsumerWidget {
  const IOSScaffoldPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Function(BuildContext)?>(contextConsumer, (_, next) {
      next?.call(context);
    });
    ref.listen<AsyncValue<YubiKeyData>>(currentDeviceDataProvider, (
      previous,
      next,
    ) {
      final path = next.value?.node.path;
      if (path != null && path == previous?.value?.node.path) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    final section = ref.watch(currentSectionProvider);
    final l10n = AppLocalizations.of(context);
    final title = section.getDisplayName(l10n);

    Future<void> scanNfc() async {
      try {
        await triggerNfcDeviceInfoScan();
      } on PlatformException catch (error, stack) {
        _log.warning('NFC device scan failed', error, stack);
        if (context.mounted) {
          showExceptionMessage(context, error);
        }
      }
    }

    if (section == Section.home || section == Section.accounts) {
      final node = ref.watch(currentDeviceProvider);
      if (node != null) {
        return ref
            .watch(currentDeviceDataProvider)
            .when(
              data: (data) => section == Section.home
                  ? HomeScreen(data, onRefresh: scanNfc)
                  : _IosAccountsScreen(data),
              loading: () => DeviceErrorScreen(node),
              error: (error, _) => DeviceErrorScreen(node, error: error),
            );
      }
      final deviceError = ref.watch(currentDeviceDataProvider).asError;
      if (deviceError != null) {
        return HomeMessagePage(
          onRefresh: scanNfc,
          centered: true,
          delayedContent: false,
          graphic: Image.asset(
            'assets/graphics/no-key.png',
            filterQuality: .medium,
            scale: 2,
            color: Theme.of(context).colorScheme.error,
          ),
          header: l10n.l_yk_no_access,
          message: deviceError.error.toString(),
        );
      }
      return HomeMessagePage(
        onRefresh: scanNfc,
        centered: true,
        delayedContent: false,
        graphic: Image.asset(
          'assets/graphics/no-key.png',
          filterQuality: .medium,
          scale: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
        header: l10n.l_insert_or_tap_yk,
      );
    }

    return AppPage(
      title: title,
      centered: true,
      builder: (context, expanded) => Text(
        'Currently not implemented',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

/// Accounts for the displayed YubiKey. Over NFC, OATH is only read when the
/// user pulls to scan.
class _IosAccountsScreen extends ConsumerWidget {
  final YubiKeyData data;

  const _IosAccountsScreen(this.data);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final devicePath = data.node.path;
    final status = ref.watch(iosOathSessionStatusProvider(devicePath));
    final isNfc = data.node.transport == Transport.nfc;

    Future<void> refresh() async {
      try {
        await refreshIosOath(ref, devicePath);
      } on CancellationException {
        // Closing the NFC sheet keeps the current accounts.
      } on Exception catch (error, stack) {
        _log.warning('OATH refresh failed', error, stack);
        if (context.mounted) {
          showExceptionMessage(context, error);
        }
      }
    }

    if (isNfc && !ref.watch(iosOathNfcReadRequestedProvider(devicePath))) {
      return MessagePage(
        onRefresh: refresh,
        title: l10n.s_accounts,
        capabilities: const [Capability.oath],
        centered: true,
        delayedContent: false,
        graphic: Image.asset(
          'assets/graphics/no-key.png',
          filterQuality: .medium,
          scale: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
        header: l10n.s_nfc_tap_your_yubikey,
      );
    }

    final error = status.asError?.error;
    if (error != null && !status.hasValue) {
      final cause = error is OathStateReadException ? error.cause : error;
      return MessagePage(
        onRefresh: refresh,
        title: l10n.s_accounts,
        capabilities: const [Capability.oath],
        centered: true,
        delayedContent: false,
        graphic: Icon(
          Symbols.error,
          size: 96,
          color: Theme.of(context).colorScheme.error,
        ),
        header: l10n.l_error_occurred,
        message: cause is PlatformException
            ? cause.message ?? cause.code
            : cause.toString(),
      );
    }

    return OathScreen(devicePath, onRefresh: refresh);
  }
}
