/*
 * Copyright (C) 2024-2025 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../generated/l10n/app_localizations.dart';

enum FlexLayout {
  list,
  grid;

  IconData get icon => switch (this) {
    FlexLayout.list => Symbols.list,
    FlexLayout.grid => Symbols.grid_view,
  };
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    FlexLayout.list => l10n.s_list_layout,
    FlexLayout.grid => l10n.s_grid_layout,
  };
}

class FlexBox<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T value) itemBuilder;
  final FlexLayout layout;
  final double cellMinWidth;
  final double spacing;
  final double runSpacing;
  const FlexBox({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.cellMinWidth,
    this.layout = FlexLayout.list,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
  });

  int _getItemsPerRow(double width) {
    // Calculate the maximum number of cells that can fit in one row
    int cellsPerRow = (width / (cellMinWidth + spacing)).floor();

    // Ensure there's at least one cell per row
    if (cellsPerRow < 1) {
      cellsPerRow = 1;
    }

    // Calculate the total width needed for the calculated number of cells and spacing
    double totalWidthNeeded =
        cellsPerRow * cellMinWidth + (cellsPerRow - 1) * spacing;

    // Adjust the number of cells per row if the calculated total width exceeds the available width
    if (totalWidthNeeded > width) {
      cellsPerRow = cellsPerRow - 1 > 0 ? cellsPerRow - 1 : 1;
    }

    return cellsPerRow;
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
            ? _getItemsPerRow(width)
            : 1;
        final chunks = getChunks(itemsPerRow);

        return Column(
          children: [
            for (final c in chunks) ...[
              if (chunks.indexOf(c) > 0) SizedBox(height: runSpacing),
              Row(
                children: [
                  for (final entry in c) ...[
                    Flexible(child: itemBuilder(entry)),
                    if (itemsPerRow != 1 && c.indexOf(entry) != c.length - 1)
                      SizedBox(width: spacing),
                  ],
                  if (c.length < itemsPerRow) ...[
                    // Prevents resizing when an item is removed
                    SizedBox(width: 8 * (itemsPerRow - c.length).toDouble()),
                    Spacer(flex: itemsPerRow - c.length),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
