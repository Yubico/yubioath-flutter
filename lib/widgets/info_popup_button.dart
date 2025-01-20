import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (!showDialog) {
      return PopupMenuButton(
        tooltip: l10n.s_more_info,
        constraints: BoxConstraints(maxWidth: 250, maxHeight: 400),
        key: _menuKey,
        popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        menuPadding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(
            Symbols.info,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
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
          tooltip: l10n.s_more_info,
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
            Symbols.info,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
        ),
      );
    }
  }
}
