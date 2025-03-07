/*
 * Copyright (C) 2023-2025 Yubico.
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

import '../generated/l10n/app_localizations.dart';

enum NfcTapAction {
  noAction,
  launch,
  copy,
  launchAndCopy;

  String getDescription(AppLocalizations l10n) => switch (this) {
        NfcTapAction.noAction => l10n.l_do_nothing,
        NfcTapAction.launch => l10n.l_launch_ya,
        NfcTapAction.copy => l10n.l_copy_otp_clipboard,
        NfcTapAction.launchAndCopy => l10n.l_launch_and_copy_otp
      };
}
