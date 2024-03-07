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

/// TextFormField without autocorrect and suggestions
// ignore: must_be_immutable
class AppTextFormField extends TextFormField {
  final AppInputDecoration? decoration;
  bool _initialized = false;
  AppTextFormField({
    // default settings to turn off autocorrect
    super.autocorrect = false,
    super.enableSuggestions = false,
    super.keyboardType = TextInputType.text,
    // forward other TextField parameters
    super.key,
    super.controller,
    super.initialValue,
    super.focusNode,
    this.decoration,
    super.textCapitalization,
    super.textInputAction,
    super.style,
    super.strutStyle,
    super.textDirection,
    super.textAlign,
    super.textAlignVertical,
    super.autofocus,
    super.readOnly,
    super.toolbarOptions,
    super.showCursor,
    super.obscuringCharacter,
    super.obscureText,
    super.smartDashesType,
    super.smartQuotesType,
    super.maxLengthEnforcement,
    super.maxLines,
    super.minLines,
    super.expands,
    super.maxLength,
    super.onChanged,
    super.onTap,
    super.onTapOutside,
    super.onEditingComplete,
    super.onFieldSubmitted,
    super.onSaved,
    super.validator,
    super.inputFormatters,
    super.enabled,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.keyboardAppearance,
    super.scrollPadding,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.buildCounter,
    super.scrollPhysics,
    super.autofillHints,
    super.autovalidateMode,
    super.scrollController,
    super.restorationId,
    super.enableIMEPersonalizedLearning,
    super.mouseCursor,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.undoController,
    super.onAppPrivateCommand,
    super.cursorOpacityAnimates,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.dragStartBehavior,
    super.contentInsertionConfiguration,
    super.clipBehavior,
    super.scribbleEnabled,
    super.canRequestFocus,
  }) : super(decoration: decoration) {
    // TODO: Replace this with a custom lint check, if possible
    Timer.run(() {
      assert(_initialized, 'AppTextFormField not initialized!');
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
