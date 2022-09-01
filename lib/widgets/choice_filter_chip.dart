import 'dart:async';

import 'package:flutter/material.dart';

class ChoiceFilterChip<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final Widget Function(T value) itemBuilder;
  final void Function(T value)? onChanged;
  const ChoiceFilterChip({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
  });

  @override
  State<ChoiceFilterChip<T>> createState() => _ChoiceFilterChipState<T>();
}

class _ChoiceFilterChipState<T> extends State<ChoiceFilterChip<T>> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      labelPadding: const EdgeInsets.only(left: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.itemBuilder(widget.value),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              _showing ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Theme.of(context).chipTheme.checkmarkColor,
            ),
          ),
        ],
      ),
      selected: true,
      showCheckmark: false,
      onSelected: widget.onChanged != null
          ? (_) async {
              final RenderBox chipBox =
                  context.findRenderObject()! as RenderBox;
              final RenderBox overlay = Navigator.of(context)
                  .overlay!
                  .context
                  .findRenderObject()! as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  chipBox.localToGlobal(chipBox.size.bottomLeft(Offset.zero),
                      ancestor: overlay),
                  chipBox.localToGlobal(chipBox.size.bottomRight(Offset.zero),
                      ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );

              setState(() {
                _showing = true;
              });
              try {
                final selected = await showMenu(
                  context: context,
                  position: position,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  color: Theme.of(context).colorScheme.background,
                  items: widget.items
                      .map((e) => PopupMenuItem<T>(
                            value: e,
                            height: chipBox.size.height,
                            textStyle: Theme.of(context).chipTheme.labelStyle,
                            child: widget.itemBuilder(e),
                          ))
                      .toList(),
                );
                if (selected != null) {
                  widget.onChanged?.call(selected);
                }
              } finally {
                // Give the menu some time to rollup before switching state.
                Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _showing = false;
                  });
                });
              }
            }
          : null,
    );
  }
}
