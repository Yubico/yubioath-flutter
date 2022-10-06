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

class CopyIntent extends Intent {
  const CopyIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

final ctrlOrCmd =
    Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

final globalShortcuts = {
  LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyC): const CopyIntent(),
  LogicalKeySet(ctrlOrCmd, LogicalKeyboardKey.keyF): const SearchIntent(),
};
