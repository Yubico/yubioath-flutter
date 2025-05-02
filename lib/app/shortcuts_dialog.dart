import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/app_localizations.dart';
import '../widgets/responsive_dialog.dart';
import 'shortcuts.dart';

extension on SingleActivator {
  List<String> getElements() {
    final modifiers = [];

    if (control) {
      modifiers.add(Platform.isMacOS ? '⌃' : 'Ctrl');
    }
    if (alt) {
      modifiers.add(Platform.isMacOS ? '⌥' : 'Alt');
    }
    if (shift) {
      modifiers.add(Platform.isMacOS ? '⇧' : 'Shift');
    }
    if (meta) {
      modifiers.add(Platform.isMacOS ? '⌘' : 'Meta');
    }

    String keyLabel;
    if (trigger == LogicalKeyboardKey.space) {
      keyLabel = 'Space';
    } else {
      keyLabel = trigger.keyLabel;
    }

    return [...modifiers, keyLabel];
  }
}

const _ignoredTriggers = [LogicalKeyboardKey.copy];

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemIntents = getItemIntents(Object());
    final globalIntents = getGlobalIntents();
    return ResponsiveDialog(
      title: Text('Keyboard Shortcuts'),
      showDialogCloseButton: false,
      builder: (context, fullScreen) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8.0,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Global shortcuts', style: theme.textTheme.titleMedium),
                  const Divider(),
                ],
              ),
              ...globalIntents.entries.map(
                (e) => _IntentItem(intent: e.key, shortcuts: e.value),
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application shortcuts',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Divider(),
                ],
              ),
              ...itemIntents.entries.map(
                (e) => _IntentItem(intent: e.key, shortcuts: e.value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntentItem extends StatelessWidget {
  final AppIntent intent;
  final List<SingleActivator> shortcuts;
  const _IntentItem({required this.intent, required this.shortcuts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(intent.getDescription(l10n)),
        _ShortcutsItem(shortcuts: shortcuts),
      ],
    );
  }
}

class _ShortcutsItem extends StatelessWidget {
  final List<SingleActivator> shortcuts;
  const _ShortcutsItem({required this.shortcuts});

  Widget _buildShortcut(BuildContext context, SingleActivator shortcut) {
    final theme = Theme.of(context);
    final elements = shortcut.getElements();
    return Row(
      spacing: 4.0,
      children:
          elements
              .map(
                (e) => Container(
                  constraints: BoxConstraints(minWidth: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  padding: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  child: Text(
                    e,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        shortcuts.where((s) => !_ignoredTriggers.contains(s.trigger)).toList();
    return Row(
      children: [
        for (var i = 0; i < filtered.length; i++) ...[
          _buildShortcut(context, filtered[i]),
          if (i < filtered.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('or'),
            ),
        ],
      ],
    );
  }
}
