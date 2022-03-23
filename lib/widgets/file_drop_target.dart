import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class FileDropTarget extends StatefulWidget {
  final Widget child;
  final Function(List<int> filedata) onFileDropped;
  final Widget? overlay;

  const FileDropTarget({
    Key? key,
    required this.child,
    required this.onFileDropped,
    this.overlay,
  }) : super(key: key);

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
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_hovering) widget.overlay ?? _buildDefaultOverlay(),
          ],
        ),
      );
}
