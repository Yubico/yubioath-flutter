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

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../core/state.dart';

class FileDropTarget extends StatefulWidget {
  final Widget child;
  final Function(List<int> filedata) onFileDropped;
  final Widget? overlay;

  const FileDropTarget({
    super.key,
    required this.child,
    required this.onFileDropped,
    this.overlay,
  });

  @override
  State<StatefulWidget> createState() => _FileDropTargetState();
}

class _FileDropTargetState extends State<FileDropTarget> {
  bool _hovering = false;

  Widget _buildDefaultOverlay() => Positioned.fill(
        child: Container(
          color: Colors.blue.withOpacity(0.4),
          child: Icon(
            Icons.upload_file,
            size: 200,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => DropTarget(
        onDragEntered: (_) {
          setState(() {
            _hovering = true;
          });
        },
        onDragExited: (_) {
          setState(() {
            _hovering = false;
          });
        },
        onDragDone: (details) async {
          for (final file in details.files) {
            widget.onFileDropped(await file.readAsBytes());
          }
        },
        enable: !isAndroid,
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_hovering) widget.overlay ?? _buildDefaultOverlay(),
          ],
        ),
      );
}
