import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app/message.dart';
import 'responsive_dialog.dart';

class InfoPopupButton extends StatelessWidget {
  final RichText infoText;
  final bool showDialog;
  const InfoPopupButton(
      {super.key, required this.infoText, this.showDialog = false});

  Widget _buildInfoContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: infoText,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showDialog) {
      return PopupMenuButton(
        popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        menuPadding: EdgeInsets.zero,
        icon: Icon(Symbols.info),
        itemBuilder: (context) {
          return [
            PopupMenuItem(enabled: false, child: _buildInfoContent(context))
          ];
        },
      );
    } else {
      return IconButton(
        onPressed: () {
          // Show info content in dialog on smaller screens and mobile
          showBlurDialog(
            context: context,
            builder: (context) => ResponsiveDialog(
              forceDialog: true,
              child: _buildInfoContent(context),
            ),
          );
        },
        icon: Icon(Symbols.info),
      );
    }
  }
}
