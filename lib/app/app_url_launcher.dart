/*
 * Copyright (C) 2022 Yubico.
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

import 'package:url_launcher/url_launcher.dart';

import '../core/state.dart';

void launchFeedbackUrl() => _launchUrl(isAndroid
    ? 'https://yubi.co/ya-feedback-android'
    : 'https://yubi.co/ya-feedback-desktop');

void launchHelpUrl() => _launchUrl(isAndroid
    ? 'https://yubi.co/ya-help-android'
    : 'https://yubi.co/ya-help-desktop');

void launchTermsUrl() => _launchUrl('https://yubi.co/terms');

void launchPrivacyUrl() => _launchUrl('https://yubi.co/privacy');

Future<bool> _launchUrl(String url) async => await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
