/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/app_localizations.dart';

/// Get the number of bytes used by a String when encoded to UTF-8.
int byteLength(String value) => utf8.encode(value).length;

/// Builds a counter widget showing number of bytes used/available.
///
/// Set this as a [TextField.buildCounter] callback to show the number of bytes
/// used rather than number of characters. [currentValue] should always match
/// the input text value to measure.
InputCounterWidgetBuilder buildByteCounterFor(String currentValue) =>
    (context, {required currentLength, required isFocused, maxLength}) {
      final theme = Theme.of(context);
      final caption = theme.textTheme.bodySmall;
      final used = byteLength(currentValue);
      final style = (used <= (maxLength ?? 0))
          ? caption
          : caption?.copyWith(color: theme.colorScheme.error);
      if (maxLength != null && isFocused) {
        final view = View.of(context);
        final announcement = AppLocalizations.of(
          context,
        ).l_characters_used(used, maxLength);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SemanticsService.sendAnnouncement(view, announcement, .ltr);
        });
      }
      return Text(
        maxLength != null ? '$used/$maxLength' : '',
        style: style,
        semanticsLabel: maxLength != null
            ? AppLocalizations.of(context).l_characters_used(used, maxLength)
            : null,
      );
    };

/// Limits the input in length based on the byte length when encoded.
/// This is generally used together with [buildByteCounterFor].
TextInputFormatter limitBytesLength(int maxByteLength) =>
    TextInputFormatter.withFunction((oldValue, newValue) {
      final newLength = byteLength(newValue.text);
      if (newLength <= maxByteLength) {
        return newValue;
      }
      return oldValue;
    });
