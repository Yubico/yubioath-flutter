import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/logger.dart';
import 'package:yubico_authenticator/android/views/beta_dialog.dart';
import 'package:yubico_authenticator/android/window_state_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import 'management/state.dart';
import 'oath/state.dart';
import 'qr_scanner/qr_scanner_provider.dart';
import 'state.dart';
import 'tap_request_dialog.dart';

Future<Widget> initialize() async {
  _initSystemUi();

  if (kDebugMode) {
    Logger.root.level = Levels.DEBUG;
  }

  _initLicenses();

  return ProviderScope(
    overrides: [
      supportedAppsProvider.overrideWithValue([
        Application.oath,
      ]),
      prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
      logLevelProvider.overrideWithProvider(androidLogProvider),
      attachedDevicesProvider
          .overrideWithProvider(androidAttachedDevicesProvider),
      currentDeviceDataProvider.overrideWithProvider(androidDeviceDataProvider),
      oathStateProvider.overrideWithProvider(androidOathStateProvider),
      credentialListProvider
          .overrideWithProvider(androidCredentialListProvider),
      currentAppProvider.overrideWithProvider(androidSubPageProvider),
      managementStateProvider.overrideWithProvider(androidManagementState),
      currentDeviceProvider.overrideWithProvider(androidCurrentDeviceProvider),
      qrScannerProvider.overrideWithProvider(androidQrScannerProvider),
      windowStateProvider.overrideWithProvider(androidWindowStateProvider)
    ],
    child: DismissKeyboard(
      child: YubicoAuthenticatorApp(page: Consumer(
        builder: (context, ref, child) {
          // activates the sub page provider
          ref.read(androidSubPageProvider);

          // activates window state provider
          ref.read(androidWindowStateProvider);

          /// initializes global handler for dialogs
          ref.read(androidDialogProvider);

          var betaDialog = BetaDialog(context, ref);
          betaDialog.request();

          return const MainPage();
        },
      )),
    ),
  );
}

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // De-select any selected node when tapping outside.
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}

void _initSystemUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true));
}

void _initLicenses() async {
  const licenseDir = 'assets/licenses/android';

  final androidProjectsToLicenseUrl = await rootBundle.loadStructuredData<List>(
    '$licenseDir/android.json',
    (value) async => jsonDecode(value),
  );

  // mapping from url to license text
  final fileMap = await rootBundle.loadStructuredData<Map>(
    '$licenseDir/map.json',
    (value) async => jsonDecode(value),
  );

  final urlToLicense = <String, String>{};
  fileMap.forEach((url, file) async {
    String licenseText = url;
    try {
      licenseText = await rootBundle.loadString('$licenseDir/$file');
      urlToLicense[url] = licenseText;
    } catch (_) {
      // failed to read license file, will use the url
    }
  });

  if (androidProjectsToLicenseUrl.isNotEmpty) {
    LicenseRegistry.addLicense(() async* {
      for (final e in androidProjectsToLicenseUrl) {
        var licenseUrl = e['PackageLicense'];
        var content = licenseUrl;
        if (urlToLicense.containsKey(licenseUrl)) {
          content = '${urlToLicense[licenseUrl]}\n\n$licenseUrl\n\n';
        }
        yield LicenseEntryWithLineBreaks([e['PackageName']], content);
      }
    });
  }
}
