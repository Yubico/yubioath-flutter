import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final List<Widget>? actions;

  const ResponsiveDialog(
      {Key? key, required this.child, this.title, this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    if (query.size.width < 540) {
      // Fullscreen
      return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: Scaffold(
            appBar: AppBar(
              title: title,
              actions: actions,
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
        actions: actions,
      );
    }
  }
}
