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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../oath/keys.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

final ctrlOrCmd =
    Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

final _globalShortcuts = {
  LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyC): const CopyIntent(),
  if (Platform.isMacOS)
    LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyQ): const CloseIntent(),
  LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyW): const CloseIntent(),
  LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyF): const SearchIntent(),
};

final _globalActions = <Type, Action<Intent>>{
  CloseIntent: CallbackAction(onInvoke: (_) {
    windowManager.close();
    return null;
  }),
  SearchIntent: CallbackAction(onInvoke: (intent) {
    // If the OATH view doesn't have focus, but is shown, find and select the search bar.
    final searchContext = searchAccountsField.currentContext;
    if (searchContext != null) {
      if (!Navigator.of(searchContext).canPop()) {
        return Actions.maybeInvoke(searchContext, intent);
      }
    }
    return null;
  }),
};

Widget registerGlobalShortcuts(Widget child) => Actions(
      actions: _globalActions,
      child: Shortcuts(
        shortcuts: _globalShortcuts,
        child: child,
      ),
    );
