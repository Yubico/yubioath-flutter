import 'package:flutter/material.dart';

import '../app/message.dart';
import 'responsive_dialog.dart';

final _menuKey = GlobalKey();

class InfoPopupButton extends StatelessWidget {
  final RichText infoText;
  final bool showDialog;
  final double? iconSize;
  final double? size;
  const InfoPopupButton({
    super.key,
    required this.infoText,
    this.showDialog = false,
    this.iconSize,
    this.size,
  });

  Widget _buildInfoContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: SingleChildScrollView(child: infoText),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showDialog) {
      return PopupMenuButton(
        constraints: BoxConstraints(maxWidth: 250, maxHeight: 400),
        key: _menuKey,
        popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        menuPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Material(
          child: SizedBox(
            height: size,
            width: size,
            child: IconButton(
              constraints: size != null
                  ? BoxConstraints(maxHeight: size!, maxWidth: size!)
                  : null,
              onPressed: () {
                dynamic state = _menuKey.currentState;
                state.showButtonMenu();
              },
              icon: Icon(
                Icons.info,
                size: iconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        itemBuilder: (context) {
          return [
            PopupMenuItem(enabled: false, child: _buildInfoContent(context))
          ];
        },
      );
    } else {
      return SizedBox(
        height: size,
        width: size,
        child: IconButton(
          constraints: size != null
              ? BoxConstraints(maxHeight: size!, maxWidth: size!)
              : null,
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
          icon: Icon(
            Icons.info,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
        ),
      );
    }
  }
}
