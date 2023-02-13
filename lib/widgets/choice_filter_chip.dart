/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:async';

import 'package:flutter/material.dart';

class ChoiceFilterChip<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final Widget Function(T value) itemBuilder;
  final Widget Function(T value)? labelBuilder;
  final void Function(T value)? onChanged;
  final Widget? avatar;
  final bool selected;
  const ChoiceFilterChip({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.avatar,
    this.selected = false,
    this.labelBuilder,
  });

  @override
  State<ChoiceFilterChip<T>> createState() => _ChoiceFilterChipState<T>();
}

class _ChoiceFilterChipState<T> extends State<ChoiceFilterChip<T>> {
  bool _showing = false;

  Future<T?> _showPickerMenu() async {
    final RenderBox chipBox = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        chipBox.localToGlobal(chipBox.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        chipBox.localToGlobal(chipBox.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    return await showMenu(
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
                textStyle: ChipTheme.of(context).labelStyle,
                child: widget.itemBuilder(e),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: widget.avatar,
      labelPadding: const EdgeInsets.only(left: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          (widget.labelBuilder ?? widget.itemBuilder).call(widget.value),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              _showing ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: ChipTheme.of(context).checkmarkColor,
              size: 18,
            ),
          ),
        ],
      ),
      selected: widget.selected,
      showCheckmark: false,
      onSelected: widget.onChanged != null
          ? (_) async {
              setState(() {
                _showing = true;
              });
              try {
                final selected = await _showPickerMenu();
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
