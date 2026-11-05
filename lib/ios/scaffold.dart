import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/message.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/app_page.dart';
import '../app/views/device_error_screen.dart';
import '../generated/l10n/app_localizations.dart';
import '../home/views/home_message_page.dart';
import '../home/views/home_screen.dart';
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
      final serial = next.value?.info.serial;
      if (serial != null && serial == previous?.value?.info.serial) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    final section = ref.watch(currentSectionProvider);
    final l10n = AppLocalizations.of(context);
    final title = section.getDisplayName(l10n);

    if (section == Section.home) {
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

      final node = ref.watch(currentDeviceProvider);
      if (node != null) {
        return ref
            .watch(currentDeviceDataProvider)
            .when(
              data: (data) => HomeScreen(data, onRefresh: scanNfc),
              loading: () => DeviceErrorScreen(node),
              error: (error, _) => DeviceErrorScreen(node, error: error),
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
