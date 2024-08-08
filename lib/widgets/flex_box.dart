import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

enum FlexLayout {
  list,
  grid;

  IconData get icon => switch (this) {
        FlexLayout.list => Symbols.list,
        FlexLayout.grid => Symbols.grid_view
      };
  String getDisplayName(AppLocalizations l10n) => switch (this) {
        FlexLayout.list => l10n.s_list_layout,
        FlexLayout.grid => l10n.s_grid_layout
      };
}

class FlexBox<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T value) itemBuilder;
  final int Function(double width)? getItemsPerRow;
  final FlexLayout layout;
  final double? spacing;
  final double? runSpacing;
  const FlexBox({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.getItemsPerRow,
    this.layout = FlexLayout.list,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
  });

  int _getItemsPerRow(double width) {
    int itemsPerRow = 1;
    if (layout == FlexLayout.grid) {
      if (width <= 420) {
        // single column
        itemsPerRow = 1;
      } else if (width <= 620) {
        // 2 column
        itemsPerRow = 2;
      } else if (width < 860) {
        // 3 column
        itemsPerRow = 3;
      } else if (width < 1200) {
        // 4 column
        itemsPerRow = 4;
      } else if (width < 1500) {
        // 5 column
        itemsPerRow = 5;
      } else if (width < 1800) {
        // 6 column
        itemsPerRow = 6;
      } else if (width < 2000) {
        // 7 column
        itemsPerRow = 7;
      } else {
        // 8 column
        itemsPerRow = 8;
      }
    }
    return itemsPerRow;
  }

  List<List<T>> getChunks(int itemsPerChunk) {
    List<List<T>> chunks = [];
    final numChunks = (items.length / itemsPerChunk).ceil();
    for (int i = 0; i < numChunks; i++) {
      final index = i * itemsPerChunk;
      int endIndex = index + itemsPerChunk;

      if (endIndex > items.length) {
        endIndex = items.length;
      }

      chunks.add(items.sublist(index, endIndex));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemsPerRow = layout == FlexLayout.grid
            ? getItemsPerRow?.call(width) ?? _getItemsPerRow(width)
            : 1;
        final chunks = getChunks(itemsPerRow);

        return Column(
          children: [
            for (final c in chunks) ...[
              if (chunks.indexOf(c) > 0) SizedBox(height: runSpacing),
              Row(
                children: [
                  for (final entry in c) ...[
                    Flexible(
                      child: itemBuilder(entry),
                    ),
                    if (itemsPerRow != 1 && c.indexOf(entry) != c.length - 1)
                      SizedBox(width: spacing),
                  ],
                  if (c.length < itemsPerRow) ...[
                    // Prevents resizing when an items is removed
                    SizedBox(width: 8 * (itemsPerRow - c.length).toDouble()),
                    Spacer(
                      flex: itemsPerRow - c.length,
                    )
                  ]
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}
