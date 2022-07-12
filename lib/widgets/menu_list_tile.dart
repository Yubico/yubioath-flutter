import 'dart:async';

import 'package:flutter/material.dart';

PopupMenuItem buildMenuItem({
  required Widget title,
  Widget? leading,
  String? trailing,
  void Function()? action,
}) =>
    PopupMenuItem(
      enabled: action != null,
      onTap: () {
        // Wait for popup menu to close before running action.
        Timer.run(action!);
      },
      child: ListTile(
        enabled: action != null,
        dense: true,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        title: title,
        leading: leading,
        trailing: trailing != null
            ? Opacity(
                opacity: 0.5,
                child: Text(trailing, textScaleFactor: 0.7),
              )
            : null,
      ),
    );
