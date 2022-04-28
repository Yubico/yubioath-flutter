import 'package:flutter/material.dart';

abstract class UserInteractionController {
  void updateContent({String? title, String? description, Widget? icon});
  void close();
}

class _UserInteractionController extends UserInteractionController
    with ChangeNotifier {
  final void Function() onClosed;
  String title;
  String description;
  Widget? icon;
  _UserInteractionController({
    required this.onClosed,
    required this.title,
    required this.description,
    this.icon,
  });

  @override
  void close() {
    onClosed();
  }

  @override
  void updateContent({String? title, String? description, Widget? icon}) {
    if (title != null) {
      this.title = title;
    }
    if (description != null) {
      this.description = description;
    }
    if (icon != null) {
      this.icon = icon;
    }
    notifyListeners();
  }
}

class _UserInteractionDialog extends StatefulWidget {
  final _UserInteractionController controller;
  const _UserInteractionDialog({Key? key, required this.controller})
      : super(key: key);

  @override
  State<_UserInteractionDialog> createState() => _UserInteractionDialogState();
}

class _UserInteractionDialogState extends State<_UserInteractionDialog> {
  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget? icon = widget.controller.icon;
    return AlertDialog(
      scrollable: true,
      title: Text(widget.controller.title),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) icon,
            Text(
              widget.controller.description,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }
}

UserInteractionController promptUserInteraction(
  BuildContext context, {
  required String title,
  required String description,
  Widget? icon,
  void Function()? onCancel,
}) {
  final controller = _UserInteractionController(
    title: title,
    description: description,
    icon: icon,
    onClosed: () {
      Navigator.of(context).pop();
    },
  );
  showDialog(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            if (onCancel != null) {
              onCancel();
              return true;
            } else {
              return false;
            }
          },
          child: _UserInteractionDialog(
            controller: controller,
          ),
        );
      });

  return controller;
}
