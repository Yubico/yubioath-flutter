import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Function()? onCancel;

  const ResponsiveDialog(
      {super.key,
      required this.child,
      this.title,
      this.actions = const [],
      this.onCancel});

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
          return Scaffold(
            appBar: AppBar(
              title: widget.title,
              actions: widget.actions,
              leading: CloseButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              child: SafeArea(
                  child: Container(key: _childKey, child: widget.child)),
            ),
          );
        } else {
          // Dialog
          final cancelText = widget.onCancel == null && widget.actions.isEmpty
              ? AppLocalizations.of(context)!.widgets_close
              : AppLocalizations.of(context)!.widgets_cancel;
          return AlertDialog(
            title: widget.title,
            titlePadding: const EdgeInsets.only(top: 24, left: 18, right: 18),
            scrollable: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
          );
        }
      }));
}
