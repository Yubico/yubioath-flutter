/*
 * Copyright (C) 2024 Yubico.
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

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

class NfcEvent {
  const NfcEvent();
}

class NfcHideViewEvent extends NfcEvent {
  final Duration hideAfter;

  const NfcHideViewEvent({required this.hideAfter});
}

class NfcCancelEvent extends NfcEvent {
  const NfcCancelEvent();
}

class NfcSetViewEvent extends NfcEvent {
  final Widget child;
  final bool showIfHidden;

  const NfcSetViewEvent({required this.child, this.showIfHidden = true});
}

@freezed
class NfcView with _$NfcView {
  factory NfcView(
      {required bool isShowing,
      required Widget child,
      bool? showCloseButton,
      bool? showSuccess,
      String? operationSuccess,
      String? operationFailure}) = _NfcView;
}

@freezed
class NfcEventCommand with _$NfcEventCommand {
  factory NfcEventCommand({
    @Default(NfcEvent()) NfcEvent event,
  }) = _NfcEventCommand;
}

NfcEventCommand hideNfcView([Duration hideAfter = Duration.zero]) =>
    NfcEventCommand(event: NfcHideViewEvent(hideAfter: hideAfter));

NfcEventCommand setNfcView(Widget child, {bool showIfHidden = true}) =>
    NfcEventCommand(
        event: NfcSetViewEvent(child: child, showIfHidden: showIfHidden));
