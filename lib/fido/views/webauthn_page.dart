/*
 * Copyright (C) 2024-2025 Yubico.
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

import 'package:flutter/material.dart';

import '../../app/views/message_page.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';

class WebAuthnScreen extends StatefulWidget {
  const WebAuthnScreen({super.key});

  @override
  State<WebAuthnScreen> createState() => _WebAuthnScreenState();
}

class _WebAuthnScreenState extends State<WebAuthnScreen> {
  bool hide = true;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // We need this to avoid unwanted app switch animation
    if (hide) {
      Timer.run(() {
        setState(() {
          hide = false;
        });
      });
    }
    return MessagePage(
      title: hide ? null : l10n.s_security_key,
      capabilities: const [Capability.u2f],
      delayedContent: hide,
      header: l10n.l_ready_to_use,
      message: l10n.l_register_sk_on_websites,
    );
  }
}
