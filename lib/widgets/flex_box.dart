import 'package:flutter/material.dart';

enum FlexLayout { grid, list }

class FlexBox<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T value) itemBuilder;
  final FlexLayout layout;
  const FlexBox({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.layout = FlexLayout.list,
  });

  int getItemsPerRow(double width) {
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
        itemsPerRow = 6;
      } else if (width < 2000) {
        itemsPerRow = 7;
      } else {
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
        final itemsPerRow = getItemsPerRow(width);
        final chunks = getChunks(itemsPerRow);

        return Column(
          children: [
            for (final c in chunks) ...[
              if (chunks.indexOf(c) > 0 && layout == FlexLayout.grid)
                const SizedBox(height: 8.0),
              Row(
                children: [
                  for (final entry in c) ...[
                    Flexible(
                      child: itemBuilder(entry),
                    ),
                    if (itemsPerRow != 1 && c.indexOf(entry) != c.length - 1)
                      const SizedBox(width: 8),
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
