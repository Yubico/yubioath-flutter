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

import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../android/app_methods.dart';

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
  Widget build(BuildContext context) => DropRegion(
        formats: Formats.standardFormats,
        //hitTestBehavior: HitTestBehavior.opaque,
        onDropEnter: (_) async {
          setState(() {
            _hovering = true;
          });
        },
        onDropLeave: (_) {
          setState(() {
            _hovering = false;
          });
        },
        onDropEnded: (event) async {
          setState(() {
            _hovering = false;
          });
          await preserveConnectedDeviceWhenPaused();
        },
        onDropOver: (event) async {
          debugPrint('onDropOver');
          return event.session.allowedOperations.firstOrNull ??
              DropOperation.none;
        },
        onPerformDrop: (PerformDropEvent event) async {

          debugPrint('onPerform');
          final reader =  event.session.items.firstOrNull?.dataReader;
          if (reader != null) {
            if (reader.canProvide(Formats.jpeg)) {
              debugPrint('received jpeg');
              reader.getFile(Formats.jpeg, (file) async {
                widget.onFileDropped(await file.readAll());
              });
            }

            if (reader.canProvide(Formats.png)) {
              debugPrint('received png');
              reader.getFile(Formats.png, (file) async {
                debugPrint('reading png data');
                final data = await file.readAll();
                debugPrint('have the png data: ${data.length}');
                widget.onFileDropped(data);
                debugPrint('leaving function');
              }, onError: (err) {
                debugPrint('error getting png file');
              });
            }
          }
          debugPrint('leaving onPerform');
        },

        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_hovering) widget.overlay ?? _buildDefaultOverlay(),
          ],
        ),
      );
}
