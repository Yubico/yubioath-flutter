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

class NfcShowViewEvent extends NfcEvent {
  final Widget child;

  const NfcShowViewEvent({required this.child});
}

class NfcHideViewEvent extends NfcEvent {
  final int timeoutMs;

  const NfcHideViewEvent({required this.timeoutMs});
}

class NfcCancelEvent extends NfcEvent {
  const NfcCancelEvent();
}

class NfcUpdateViewEvent extends NfcEvent {
  final Widget child;

  const NfcUpdateViewEvent({required this.child});
}

@freezed
class NfcView with _$NfcView {
  factory NfcView(
      {required bool isShowing,
      required Widget child,
      bool? showCloseButton,
      bool? showSuccess,
      String? operationName,
      String? operationProcessing,
      String? operationSuccess,
      String? operationFailure}) = _NfcView;
}

@freezed
class NfcEventCommand with _$NfcEventCommand {
  factory NfcEventCommand({
    @Default(NfcEvent()) NfcEvent event,
  }) = _NfcEventCommand;
}

final hideNfcView =
    NfcEventCommand(event: const NfcHideViewEvent(timeoutMs: 0));

NfcEventCommand updateNfcView(Widget child) =>
    NfcEventCommand(event: NfcUpdateViewEvent(child: child));

NfcEventCommand showNfcView(Widget child) =>
    NfcEventCommand(event: NfcShowViewEvent(child: child));
