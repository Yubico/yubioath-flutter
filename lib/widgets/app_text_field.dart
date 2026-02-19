/*
 * Copyright (C) 2023 Yubico.
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app/accessibility_announcer.dart';
import '../app/shortcuts.dart';
import 'app_input_decoration.dart';

/// TextField without autocorrect and suggestions
class AppTextField extends TextField {
  const AppTextField({
    // default settings to turn off autocorrect
    super.autocorrect = false,
    super.enableSuggestions = false,
    super.keyboardType = TextInputType.text,
    // forward other TextField parameters
    super.key,
    super.controller,
    super.focusNode,
    super.undoController,
    AppInputDecoration? decoration,
    super.textInputAction,
    super.textCapitalization,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textAlignVertical,
    super.textDirection,
    super.readOnly,
    super.toolbarOptions,
    super.showCursor,
    super.autofocus,
    super.obscuringCharacter,
    super.obscureText,
    super.smartDashesType,
    super.smartQuotesType,
    super.maxLines,
    super.minLines,
    super.expands,
    super.maxLength,
    super.maxLengthEnforcement,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates,
    super.cursorColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.keyboardAppearance,
    super.scrollPadding,
    super.dragStartBehavior,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.onTap,
    super.onTapOutside,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints,
    super.contentInsertionConfiguration,
    super.clipBehavior,
    super.restorationId,
    super.scribbleEnabled,
    super.enableIMEPersonalizedLearning,
    super.contextMenuBuilder,
    super.canRequestFocus,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
  }) : super(decoration: decoration);

  Widget init() => Builder(
    builder: (context) {
      Widget result = Shortcuts(
        shortcuts: {
          // Override escape intent
          const SingleActivator(LogicalKeyboardKey.escape): EscapeIntent(),
        },
        child: DefaultSelectionStyle(
          selectionColor: decoration?.errorText != null
              ? Theme.of(context).colorScheme.error
              : null,
          child: this,
        ),
      );

      final controller = this.controller;
      final isWindowsDesktop =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
      if (controller == null || !isWindowsDesktop) {
        return result;
      }

      return _WindowsTextSelectionAnnouncer(
        controller: controller,
        obscureText: obscureText,
        child: result,
      );
    },
  );
}

class _WindowsTextSelectionAnnouncer extends StatefulWidget {
  final TextEditingController controller;
  final bool obscureText;
  final Widget child;

  const _WindowsTextSelectionAnnouncer({
    required this.controller,
    required this.obscureText,
    required this.child,
  });

  @override
  State<_WindowsTextSelectionAnnouncer> createState() =>
      _WindowsTextSelectionAnnouncerState();
}

class _WindowsTextSelectionAnnouncerState
    extends State<_WindowsTextSelectionAnnouncer> {
  late String _lastText;
  late TextSelection _lastSelection;
  bool _liveRegionToggle = false;
  String _liveRegionLabel = '';

  @override
  void initState() {
    super.initState();
    final value = widget.controller.value;
    _lastText = value.text;
    _lastSelection = value.selection;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _WindowsTextSelectionAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      final value = widget.controller.value;
      _lastText = value.text;
      _lastSelection = value.selection;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    // Note: We intentionally don't gate on semanticsEnabled here. Some screen
    // readers on Windows can still benefit from explicit announcements even
    // when semantics are not fully enabled.

    final value = widget.controller.value;
    final nextText = value.text;
    final nextSelection = value.selection;

    final previousText = _lastText;
    final previousSelection = _lastSelection;
    _lastText = nextText;
    _lastSelection = nextSelection;

    if (widget.obscureText) {
      return;
    }

    if (nextText != previousText) {
      return;
    }

    if (!nextSelection.isCollapsed || !previousSelection.isCollapsed) {
      return;
    }

    final nextOffset = nextSelection.baseOffset;
    final previousOffset = previousSelection.baseOffset;
    if (nextOffset < 0 || previousOffset < 0) {
      return;
    }

    final delta = nextOffset - previousOffset;
    if (delta.abs() != 1) {
      return;
    }

    // Flutter reports the caret position as the insertion point (between
    // characters). NVDA typically announces the character to the right of that
    // insertion point, which also matches what the Delete key would remove.
    final charIndex = nextOffset;
    if (charIndex < 0 || charIndex >= nextText.length) {
      return;
    }

    final char = nextText[charIndex];

    // NVDA on Windows can miss caret movement announcements for editable text.
    // Keep a tiny semantics node updated and also send a platform-specific
    // notification announcement where supported.
    _liveRegionToggle = !_liveRegionToggle;
    final invisibleSuffix = _liveRegionToggle ? '\u200B' : '\u200C';
    final announcement = '$char$invisibleSuffix';
    setState(() {
      _liveRegionLabel = announcement;
    });

    unawaited(AccessibilityAnnouncer.announce(context, char));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        IgnorePointer(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: Semantics(
              container: true,
              liveRegion: true,
              label: _liveRegionLabel,
              value: _liveRegionLabel,
              child: const SizedBox(width: 1, height: 1),
            ),
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: Semantics(
              container: true,
              role: SemanticsRole.status,
              label: _liveRegionLabel,
              value: _liveRegionLabel,
              child: const SizedBox(width: 1, height: 1),
            ),
          ),
        ),
      ],
    );
  }
}
