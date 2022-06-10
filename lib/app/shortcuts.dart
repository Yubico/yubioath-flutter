import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

final globalShortcuts = {
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
      const CopyIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
      const SearchIntent(),
};
