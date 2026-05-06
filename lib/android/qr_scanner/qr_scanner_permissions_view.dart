/*
 * Copyright (C) 2022-2026 Yubico.
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

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import 'qr_scanner_widgets.dart';

class QRScannerPermissionsUI extends StatelessWidget {
  final VoidCallback onPermissionRequest;

  const QRScannerPermissionsUI({super.key, required this.onPermissionRequest});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QrScannerTopBar(),
              const SizedBox(height: 24),
              Text(
                l10n.s_qr_scan,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  l10n.p_need_camera_permission,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: FilledButton(
                  onPressed: () => onPermissionRequest(),
                  child: Text(l10n.s_review_permissions),
                ),
              ),
              const Spacer(),
              const QrScannerNoQrCodeGroup(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
