import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: ((context, constraints) {
        if (constraints.maxWidth < 540) {
          // Fullscreen
          return Dialog(
              insetPadding: const EdgeInsets.all(0),
              child: Scaffold(
                appBar: AppBar(
                  title: title,
                  actions: actions,
                  leading: BackButton(
                    onPressed: () {
                      onCancel?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: child,
                ),
              ));
        } else {
          // Dialog
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            title: title,
            scrollable: true,
            content: SizedBox(
              width: 380,
              child: child,
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
              ...actions
            ],
          );
        }
      }));
}
