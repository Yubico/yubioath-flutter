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
