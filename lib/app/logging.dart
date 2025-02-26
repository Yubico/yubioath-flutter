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

// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../android/state.dart';
import '../core/state.dart';
import '../desktop/state.dart';
import '../generated/l10n/app_localizations.dart';
import '../version.dart';
import '../widgets/choice_filter_chip.dart';
import 'message.dart';
import 'state.dart';
import 'views/keys.dart';

final _log = Logger('logging');

String _pad(int value, int zeroes) => value.toString().padLeft(zeroes, '0');

extension DateTimeFormat on DateTime {
  String get logFormat =>
      '${_pad(hour, 2)}:${_pad(minute, 2)}:${_pad(second, 2)}.${_pad(millisecond, 3)}';
}

class Levels {
  /// Key for tracing information ([value] = 500).
  static const Level TRAFFIC = Level('TRAFFIC', 500);

  /// Key for static configuration messages ([value] = 700).
  static const Level DEBUG = Level('DEBUG', 700);

  /// Key for informational messages ([value] = 800).
  static const Level INFO = Level.INFO;

  /// Key for potential problems ([value] = 900).
  static const Level WARNING = Level.WARNING;

  /// Key for serious failures ([value] = 1000).
  static const Level ERROR = Level('ERROR', 1000);

  static const List<Level> LEVELS = [TRAFFIC, DEBUG, INFO, WARNING, ERROR];
}

extension LoggerExt on Logger {
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.ERROR, message, error, stackTrace);
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.DEBUG, message, error, stackTrace);
  void traffic(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Levels.TRAFFIC, message, error, stackTrace);
}

final logLevelProvider = StateNotifierProvider<LogLevelNotifier, Level>(
  (ref) => LogLevelNotifier(),
);

class LogLevelNotifier extends StateNotifier<Level> {
  final List<String> _buffer = [];
  LogLevelNotifier() : super(Logger.root.level) {
    Logger.root.onRecord.listen((record) {
      _buffer.add(
        '${record.time.logFormat} [${record.loggerName}] ${record.level}: ${record.message}',
      );
      if (record.error != null) {
        _buffer.add('${record.error}');
      }
      while (_buffer.length > 1000) {
        _buffer.removeAt(0);
      }
    });
  }

  void setLogLevel(Level level) {
    state = level;
    Logger.root.level = level;
  }

  Future<List<String>> getLogs() async {
    return List.unmodifiable(_buffer);
  }
}

final logPanelVisibilityProvider =
    StateNotifierProvider<LogPanelVisibilityNotifier, bool>((ref) {
  return LogPanelVisibilityNotifier(false);
});

class LogPanelVisibilityNotifier extends StateNotifier<bool> {
  LogPanelVisibilityNotifier(super.initialVisiblity);

  void setVisibility(bool visibility) {
    state = visibility;
  }
}

class LoggingPanel extends ConsumerStatefulWidget {
  const LoggingPanel({super.key});

  @override
  ConsumerState<LoggingPanel> createState() => _LoggingPanelState();
}

class _LoggingPanelState extends ConsumerState<LoggingPanel> {
  bool _runningDiagnostics = false;

  List<Widget> _buildChipsList(Level logLevel) {
    final l10n = AppLocalizations.of(context);
    return [
      ChoiceFilterChip<Level>(
        avatar: Icon(
          Symbols.insights,
        ),
        value: logLevel,
        items: Levels.LEVELS,
        selected: logLevel != Level.INFO,
        labelBuilder: (value) => Text(l10n.s_log_level(
            value.name[0] + value.name.substring(1).toLowerCase())),
        itemBuilder: (value) =>
            Text('${value.name[0]}${value.name.substring(1).toLowerCase()}'),
        onChanged: (level) {
          ref.read(logLevelProvider.notifier).setLogLevel(level);
          _log.debug('Log level set to $level');
        },
      ),
      ActionChip(
        key: logChip,
        avatar: const Icon(Symbols.content_copy),
        label: Text(l10n.s_copy_log),
        onPressed: () async {
          _log.info('Copying log to clipboard ($version)...');
          final logs = await ref.read(logLevelProvider.notifier).getLogs();
          var clipboard = ref.read(clipboardProvider);
          await clipboard.setText(logs.join('\n'));
          if (!clipboard.platformGivesFeedback()) {
            await ref.read(withContextProvider)(
              (context) async {
                showMessage(context, l10n.l_log_copied);
              },
            );
          }
        },
      ),
      if (isDesktop) ...[
        ActionChip(
          key: diagnosticsChip,
          avatar: _runningDiagnostics
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                )
              : const Icon(Symbols.bug_report),
          label: Text(l10n.s_run_diagnostics),
          onPressed: () async {
            setState(() {
              _runningDiagnostics = true;
            });
            _log.info('Running diagnostics...');
            final response = await ref
                .read(rpcProvider)
                .requireValue
                .command('diagnose', []);
            final data = response['diagnostics'] as List;
            data.insert(0, {
              'app_version': version,
              'dart': Platform.version,
              'os': Platform.operatingSystem,
              'os_version': Platform.operatingSystemVersion,
            });
            data.insert(data.length - 1, ref.read(featureFlagProvider));
            final text = const JsonEncoder.withIndent('  ').convert(data);
            await ref.read(clipboardProvider).setText(text);
            setState(() {
              _runningDiagnostics = false;
            });
            await ref.read(withContextProvider)(
              (context) async {
                showMessage(context, l10n.l_diagnostics_copied);
              },
            );
          },
        ),
      ]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logLevel = ref.watch(logLevelProvider);
    final sensitiveLogs = ref.watch(
        logLevelProvider.select((level) => level.value <= Level.CONFIG.value));
    final visible = ref.watch(logPanelVisibilityProvider);

    if (!visible) {
      return const SizedBox();
    }

    return _Panel(
      sensitive: sensitiveLogs,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 4.0,
        spacing: 4.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (sensitiveLogs)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
                  child: Icon(
                    Symbols.warning_amber,
                    size: 24,
                  ),
                ),
                if (sensitiveLogs) ...[
                  const SizedBox(width: 8.0),
                  Flexible(child: Text(l10n.l_sensitive_data_logged))
                ]
              ],
            ),
          if (!sensitiveLogs)
            IconButton(
              onPressed: () {
                ref
                    .read(logPanelVisibilityProvider.notifier)
                    .setVisibility(false);
              },
              icon: Icon(Symbols.close),
            ),
          Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: _buildChipsList(logLevel),
          )
        ],
      ),
    );
  }
}

class WarningPanel extends ConsumerWidget {
  const WarningPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allowScreenshots =
        isAndroid ? ref.watch(androidAllowScreenshotsProvider) : false;

    if (!allowScreenshots) {
      return SizedBox();
    }

    return _Panel(
      sensitive: allowScreenshots,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: Icon(
              Symbols.warning_amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(child: Text(l10n.l_warning_allow_screenshots))
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final bool sensitive;
  const _Panel({required this.child, required this.sensitive});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final sensitiveColor = Color(0xFFFF1A1A);
    final sensitiveChipColor = themeData.brightness == Brightness.dark
        ? Color(0xFF832E2E)
        : Color.fromARGB(255, 223, 134, 134);
    final sensitiveChipBorderColor = themeData.brightness == Brightness.dark
        ? Color(0xFFA24848)
        : Color.fromARGB(255, 191, 98, 98);
    final seedColor =
        sensitive ? sensitiveColor : themeData.colorScheme.primary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: themeData.brightness,
    );

    final localThemeData = themeData.copyWith(
      colorScheme: colorScheme,
      chipTheme: themeData.chipTheme.copyWith(
        backgroundColor:
            sensitive ? sensitiveChipColor : colorScheme.secondaryContainer,
        selectedColor: sensitive ? sensitiveChipColor : null,
        shape: sensitive
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: sensitiveChipBorderColor,
                ),
                borderRadius: BorderRadius.circular(8.0),
              )
            : null,
      ),
    );

    final panelBackgroundColor = sensitive
        ? sensitiveColor.withValues(alpha: 0.3)
        : colorScheme.secondaryContainer.withValues(alpha: 0.3);

    return ColoredBox(
      color: colorScheme.surface,
      child: Theme(
        data: localThemeData,
        child: ColoredBox(
          color: panelBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
