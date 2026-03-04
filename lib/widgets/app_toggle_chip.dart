import 'package:flutter/material.dart';

class AppToggleChip extends StatelessWidget {
  final Key? chipKey;
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final String? tooltip;

  const AppToggleChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.tooltip,
  }) : chipKey = key,
       super(key: null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = ChipTheme.of(context);
    final colorScheme = theme.colorScheme;
    final shape = chipTheme.shape ?? const StadiumBorder();
    final enabled = onSelected != null;

    final backgroundColor = !enabled
        ? (chipTheme.disabledColor ?? colorScheme.onSurface.withValues(alpha: .12))
        : selected
        ? (chipTheme.selectedColor ?? colorScheme.secondaryContainer)
        : (chipTheme.backgroundColor ?? colorScheme.surfaceContainerHighest);

    void setSelected(bool value) {
      if (!enabled) {
        return;
      }
      onSelected?.call(value);
    }

    Widget result = Material(
      color: backgroundColor,
      shape: shape,
      child: InkWell(
        key: chipKey,
        onTap: enabled ? () => setSelected(!selected) : null,
        canRequestFocus: enabled,
        customBorder: shape,
        child: Semantics(
          checked: selected,
          enabled: enabled,
          focusable: enabled,
          onFocus: enabled ? () => Focus.maybeOf(context)?.requestFocus() : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 8,
              top: 2,
              bottom: 2,
              end: 12,
            ),
            child: Row(
              mainAxisSize: .min,
              children: [
                ExcludeFocusTraversal(
                  excluding: true,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Checkbox(
                        value: selected,
                        onChanged: enabled
                            ? (value) {
                                if (value == null) {
                                  return;
                                }
                                setSelected(value);
                              }
                            : null,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                DefaultTextStyle.merge(
                  style: chipTheme.labelStyle,
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.trim().isNotEmpty) {
      result = Tooltip(
        message: tooltip!,
        excludeFromSemantics: true,
        child: result,
      );
    }

    return result;
  }
}
