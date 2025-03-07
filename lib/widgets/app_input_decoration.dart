import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppInputDecoration extends InputDecoration {
  final List<Widget>? suffixIcons;

  const AppInputDecoration({
    // allow multiple suffixIcons
    this.suffixIcons,
    // forward other TextField parameters
    super.icon,
    super.iconColor,
    super.label,
    super.labelText,
    super.labelStyle,
    super.floatingLabelStyle,
    super.helperText,
    super.helperStyle,
    super.helperMaxLines,
    super.hintText,
    super.hintStyle,
    super.hintTextDirection,
    super.hintMaxLines,
    super.hintFadeDuration,
    super.error,
    super.errorText,
    super.errorStyle,
    super.errorMaxLines,
    super.floatingLabelBehavior,
    super.floatingLabelAlignment,
    super.isCollapsed,
    super.isDense,
    super.contentPadding,
    super.prefixIcon,
    super.prefixIconConstraints,
    super.prefix,
    super.prefixText,
    super.prefixStyle,
    super.prefixIconColor,
    super.suffixIcon,
    super.suffix,
    super.suffixText,
    super.suffixStyle,
    super.suffixIconColor,
    super.suffixIconConstraints,
    super.counter,
    super.counterText,
    super.counterStyle,
    super.filled,
    super.fillColor,
    super.focusColor,
    super.hoverColor,
    super.errorBorder,
    super.focusedBorder,
    super.focusedErrorBorder,
    super.disabledBorder,
    super.enabledBorder,
    super.border,
    super.enabled = true,
    super.semanticCounterText,
    super.alignLabelWithHint,
    super.constraints,
  }) : assert(!(suffixIcon != null && suffixIcons != null),
            'Declaring both suffixIcon and suffixIcons is not supported.');

  @override
  Widget? get suffixIcon {
    final icons = [
      if (super.suffixIcon != null) super.suffixIcon!,
      if (suffixIcons != null) ...suffixIcons!,
      if (errorText != null) const Icon(Symbols.error, fill: 1),
    ];

    return switch (icons.length) {
      0 => null,
      1 => icons.single,
      _ => Builder(
          builder: (context) {
            // Apply the constraints to *each* icon.
            final constraints = suffixIconConstraints ??
                Theme.of(context).visualDensity.effectiveConstraints(
                      const BoxConstraints(
                        minWidth: kMinInteractiveDimension,
                        minHeight: kMinInteractiveDimension,
                      ),
                    );
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                for (Widget icon in icons)
                  ConstrainedBox(
                    constraints: constraints,
                    child: icon,
                  )
              ],
            );
          },
        ),
    };
  }
}
