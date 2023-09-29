/*
 * Copyright (C) 2022-2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/logger.dart';
import 'package:yubico_authenticator/android/oath/otp_auth_link_handler.dart';
import 'package:yubico_authenticator/android/window_state_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/app.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../app/views/main_page.dart';
import '../core/state.dart';
import '../management/state.dart';
import '../oath/state.dart';
import 'app_methods.dart';
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
      supportedAppsProvider.overrideWith(implementedApps([
        Application.oath,
      ])),
      prefProvider.overrideWithValue(await SharedPreferences.getInstance()),
      logLevelProvider.overrideWith((ref) => AndroidLogger()),
      attachedDevicesProvider.overrideWith(
        () => AndroidAttachedDevicesNotifier(),
      ),
      currentDeviceDataProvider.overrideWith(
        (ref) => ref.watch(androidDeviceDataProvider),
      ),
      oathStateProvider.overrideWithProvider(androidOathStateProvider),
      credentialListProvider
          .overrideWithProvider(androidCredentialListProvider),
      currentAppProvider.overrideWith(
          (ref) => AndroidSubPageNotifier(ref.watch(supportedAppsProvider))),
      managementStateProvider.overrideWithProvider(androidManagementState),
      currentDeviceProvider.overrideWith(
        () => AndroidCurrentDeviceNotifier(),
      ),
      qrScannerProvider
          .overrideWith(androidQrScannerProvider(await getHasCamera())),
      windowStateProvider
          .overrideWith((ref) => ref.watch(androidWindowStateProvider)),
      clipboardProvider.overrideWith(
        (ref) => ref.watch(androidClipboardProvider),
      ),
      androidSdkVersionProvider.overrideWithValue(await getAndroidSdkVersion()),
      androidNfcSupportProvider.overrideWithValue(await getHasNfc()),
      supportedThemesProvider.overrideWith(
        (ref) => ref.watch(androidSupportedThemesProvider),
      )
    ],
    child: DismissKeyboard(
      child: YubicoAuthenticatorApp(page: Consumer(
        builder: (context, ref, child) {
          // activates window state provider
          ref.read(androidWindowStateProvider);

          // initializes global handler for dialogs
          ref.read(androidDialogProvider);

          // set context which will handle otpauth links
          setupOtpAuthLinkHandler(context);

          setupAppMethodsChannel(ref);

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
}

void _initLicenses() async {
  const licenseDir = 'assets/licenses/raw';

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
