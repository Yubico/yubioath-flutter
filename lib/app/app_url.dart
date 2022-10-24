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

import 'dart:io';

class AppUrl {
  static final String feedbackUrl = Platform.isAndroid
      ? 'https://yubi.co/ya-feedback-android'
      : 'https://yubi.co/ya-feedback-desktop';

  static final String helpUrl = Platform.isAndroid
      ? 'https://yubi.co/ya-help-android'
      : 'https://yubi.co/ya-help-desktop';

  static String termsUrl = 'https://yubi.co/terms';

  static String privacyUrl = 'https://yubi.co/privacy';
}
