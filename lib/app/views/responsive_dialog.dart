import 'package:flutter/material.dart';

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Function()? onCancel;

  const ResponsiveDialog(
      {Key? key,
      required this.child,
      this.title,
      this.actions = const [],
      this.onCancel})
      : super(key: key);

  @override
  State<ResponsiveDialog> createState() => _ResponsiveDialogState();
}

class _ResponsiveDialogState extends State<ResponsiveDialog> {
  final Key _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: ((context, constraints) {
        if (constraints.maxWidth < 540) {
          // Fullscreen
          return Dialog(
              insetPadding: const EdgeInsets.all(0),
              child: Scaffold(
                appBar: AppBar(
                  title: widget.title,
                  actions: widget.actions,
                  leading: BackButton(
                    onPressed: () {
                      widget.onCancel?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: Container(key: _childKey, child: widget.child),
                ),
              ));
        } else {
          // Dialog
          final cancelText = widget.onCancel == null && widget.actions.isEmpty
              ? 'Close'
              : 'Cancel';
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: AlertDialog(
              insetPadding: EdgeInsets.zero,
              title: widget.title,
              scrollable: true,
              content: SizedBox(
                width: 380,
                child: Container(key: _childKey, child: widget.child),
              ),
              actions: [
                TextButton(
                  child: Text(cancelText),
                  onPressed: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                ),
                ...widget.actions
              ],
            ),
          );
        }
      }));
}
