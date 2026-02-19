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
      // Use 'Space' instead of ' '
      keyLabel = 'Space';
    } else {
      keyLabel = trigger.keyLabel;
    }

    return [...modifiers, keyLabel];
  }
}

const _ignoredTriggers = [
  LogicalKeyboardKey.copy,
  LogicalKeyboardKey.numpadDivide,
];

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final itemIntents = getItemIntents(Object());
    final globalIntents = getGlobalIntents();
    final globalEntries = globalIntents.entries.toList();
    return ResponsiveDialog(
      title: Text(l10n.s_keyboard_shortcuts),
      builder: (context, fullScreen) {
        return Shortcuts(
          shortcuts: {
            SingleActivator(LogicalKeyboardKey.arrowDown):
                const DirectionalFocusIntent(TraversalDirection.down),
            SingleActivator(LogicalKeyboardKey.arrowUp):
                const DirectionalFocusIntent(TraversalDirection.up),
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 8.0,
              children: [
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.s_global_shortcuts,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(),
                  ],
                ),
                for (var i = 0; i < globalEntries.length; i++)
                  _IntentItem(
                    intent: globalEntries[i].key,
                    shortcuts: globalEntries[i].value,
                    autofocus: i == 0,
                  ),
                const SizedBox(height: 8.0),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.s_application_shortcuts,
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
          ),
        );
      },
    );
  }
}

class _IntentItem extends StatelessWidget {
  final AppIntent intent;
  final List<SingleActivator> shortcuts;
  final bool autofocus;
  const _IntentItem({
    required this.intent,
    required this.shortcuts,
    this.autofocus = false,
  });

  String _formatShortcut(SingleActivator shortcut) =>
      shortcut.getElements().join(' + ');

  String _semanticLabel(AppLocalizations l10n) {
    final description = intent.getDescription(l10n);
    final filtered = shortcuts
        .where((s) => !_ignoredTriggers.contains(s.trigger))
        .toList();
    if (filtered.isEmpty) {
      return description;
    }
    final shortcutsText = filtered.map(_formatShortcut).join(' / ');
    return '$description: $shortcutsText';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Focus(
      autofocus: autofocus,
      onFocusChange: (focused) {
        if (focused) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 100),
            alignment: 0.1,
          );
        }
      },
      child: Semantics(
        label: _semanticLabel(l10n),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              spacing: 4.0,
              children: [
                Flexible(
                  child: Text(
                    intent.getDescription(l10n),
                    overflow: .fade,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                _ShortcutsItem(shortcuts: shortcuts),
              ],
            ),
          ),
        ),
      ),
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
      children: elements
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
    final filtered = shortcuts
        .where((s) => !_ignoredTriggers.contains(s.trigger))
        .toList();
    return Row(
      children: [
        for (var i = 0; i < filtered.length; i++) ...[
          _buildShortcut(context, filtered[i]),
          if (i < filtered.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('/'),
            ),
        ],
      ],
    );
  }
}
