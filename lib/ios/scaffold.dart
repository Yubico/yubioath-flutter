import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/app_page.dart';
import '../generated/l10n/app_localizations.dart';

class IOSReleaseApp extends StatelessWidget {
  const IOSReleaseApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const YubicoAuthenticatorApp(page: IOSReleaseHome());
}

class IOSReleaseHome extends ConsumerWidget {
  const IOSReleaseHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(currentSectionProvider);
    final l10n = AppLocalizations.of(context);
    final title = section.getDisplayName(l10n);

    return AppPage(
      title: title,
      centered: true,
      builder: (context, expanded) => Text(
        section == Section.home
            ? 'iOS app scaffold'
            : 'Currently not implemented',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class IOSCurrentSectionNotifier extends CurrentSectionNotifier {
  IOSCurrentSectionNotifier() : super(Section.home);

  @override
  void setCurrentSection(Section section) => state = section;
}

class IOSAttachedDevicesNotifier extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => const [];
}

class IOSCurrentDeviceNotifier extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() => null;

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}
