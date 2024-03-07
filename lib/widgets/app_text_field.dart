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

import 'package:flutter/material.dart';

import 'app_input_decoration.dart';

/// TextField without autocorrect and suggestions
// ignore: must_be_immutable
class AppTextField extends TextField {
  bool _initialized = false;
  AppTextField({
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
  }) : super(decoration: decoration) {
    // TODO: Replace this with a custom lint check, if possible
    Timer.run(() {
      assert(_initialized, 'AppTextField not initialized!');
    });
  }

  Widget init() {
    _initialized = true;
    return Builder(
      builder: (context) => DefaultSelectionStyle(
        selectionColor: decoration?.errorText != null
            ? Theme.of(context).colorScheme.error
            : null,
        child: this,
      ),
    );
  }
}
