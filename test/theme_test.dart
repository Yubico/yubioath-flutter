/*
 * Copyright (C) 2026 Yubico.
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/theme.dart';

/// Font families declared in pubspec.yaml, mapped to their asset paths.
Map<String, List<String>> _declaredFonts() {
  final fonts = <String, List<String>>{};
  List<String>? current;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final family = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
    final asset = RegExp(r'^\s*- asset:\s*(\S+)').firstMatch(line);
    if (family != null) {
      current = fonts[family.group(1)!] = [];
    } else if (asset != null) {
      current?.add(asset.group(1)!);
    }
  }
  return fonts;
}

void main() {
  group('font', () {
    final themes = {
      'light': AppTheme.getLightTheme(defaultPrimaryColor),
      'dark': AppTheme.getDarkTheme(defaultPrimaryColor),
    };

    test('theme family is bundled', () {
      // An undeclared family silently falls back to the platform font.
      final fonts = _declaredFonts();
      expect(fonts.keys, contains(defaultFontFamily));
      expect(fonts[defaultFontFamily], isNotEmpty);
      for (final asset in fonts[defaultFontFamily]!) {
        expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
      }
    });

    for (final MapEntry(key: name, value: theme) in themes.entries) {
      test('$name theme uses it for text and chips', () {
        for (final style in [
          theme.textTheme.bodyMedium,
          theme.textTheme.titleLarge,
          theme.textTheme.labelLarge,
          theme.chipTheme.labelStyle,
        ]) {
          expect(style?.fontFamily, defaultFontFamily);
        }
      });
    }

    test('license is registered', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      addFontLicense();
      final entries = await LicenseRegistry.licenses
          .where((e) => e.packages.contains('Instrument Sans'))
          .toList();
      expect(entries, hasLength(1));
      final text = entries.single.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(text, contains('The Instrument Sans Project Authors'));
    });
  });

  group('Android native colors', () {
    test('green matches the default primary color', () {
      // Used for the native theme before Flutter draws.
      expect(_androidColor('values', 'yubico_green'), defaultPrimaryColor);
    });

    test('launch screen background matches the first Flutter frame', () {
      // A mismatch shows as a flash when the launch screen hands over.
      expect(
        _androidColor('values', 'splash_background'),
        AppTheme.getLightTheme(defaultPrimaryColor).colorScheme.surface,
      );
      expect(
        _androidColor('values-night', 'splash_background'),
        AppTheme.getDarkTheme(defaultPrimaryColor).colorScheme.surface,
      );
    });
  });
}

/// An opaque `#RRGGBB` color resource from the Android app.
Color _androidColor(String valuesDir, String name) {
  final colors = File(
    'android/app/src/main/res/$valuesDir/colors.xml',
  ).readAsStringSync();
  final match = RegExp(
    '<color name="$name">#([0-9A-Fa-f]{6})</color>',
  ).firstMatch(colors);
  expect(match, isNotNull, reason: '$name is missing in $valuesDir');
  return Color(0xFF000000 | int.parse(match!.group(1)!, radix: 16));
}
