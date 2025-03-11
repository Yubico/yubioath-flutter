/*
 * Copyright (C) 2024 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

class NfcIconProgressBar extends StatelessWidget {
  final bool inProgress;

  const NfcIconProgressBar(this.inProgress, {super.key});

  @override
  Widget build(BuildContext context) => IconTheme(
    data: IconThemeData(size: 64, color: Theme.of(context).colorScheme.primary),
    child: Stack(
      alignment: AlignmentDirectional.center,
      children: [
        const Opacity(opacity: 0.5, child: Icon(Symbols.contactless)),
        const ClipOval(
          child: SizedBox(
            width: 42,
            height: 42,
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Icon(Symbols.contactless),
            ),
          ),
        ),
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(value: inProgress ? null : 1.0),
        ),
      ],
    ),
  );
}

class UsbIconProgressBar extends StatelessWidget {
  final bool inProgress;

  const UsbIconProgressBar(this.inProgress, {super.key});

  @override
  Widget build(BuildContext context) => IconTheme(
        data: IconThemeData(
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            const Opacity(
              opacity: 0.0,
              child: Icon(Symbols.usb),
            ),
            const ClipOval(
              child: SizedBox(
                width: 42,
                height: 42,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Icon(Symbols.usb, size: 40),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(value: inProgress ? null : 1.0),
            ),
          ],
        ),
      );
}

class UsbIcon extends StatelessWidget {
  const UsbIcon({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Symbols.usb, size: 64, color: Theme.of(context).colorScheme.primary);
}

class NfcIconSuccess extends StatelessWidget {
  const NfcIconSuccess({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Symbols.check,
    size: 64,
    color: Theme.of(context).colorScheme.primary,
  );
}

class NfcIconFailure extends StatelessWidget {
  const NfcIconFailure({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Symbols.close, size: 64, color: Theme.of(context).colorScheme.error);
}
