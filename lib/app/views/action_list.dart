/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/tooltip_if_truncated.dart';
import '../models.dart';

class ActionListItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final void Function(BuildContext context)? onTap;
  final ActionStyle actionStyle;
  final Feature? feature;
  final double? borderRadius;

  const ActionListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.actionStyle = ActionStyle.normal,
    this.feature,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // final theme =
    //     ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;

    // final (foreground, background) = switch (actionStyle) {
    //   ActionStyle.normal => (theme.onSecondary, theme.secondary),
    //   ActionStyle.primary => (theme.onPrimary, theme.primary),
    //   ActionStyle.error => (theme.onError, theme.error),
    // };
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap == null
          ? () {
              // Needed to avoid triggering escape intent when tapping
              // on a disabled item
            }
          : null,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 48),
        ),
        title: TooltipIfTruncated(
          text: title,
          style: TextStyle(fontSize: theme.textTheme.bodyLarge!.fontSize),
        ),
        subtitle: subtitle != null
            ? TooltipIfTruncated(
                text: subtitle!,
                style: TextStyle(
                  fontSize: theme.textTheme.bodyMedium!.fontSize,
                ),
                maxLines: 2,
                overflow: .ellipsis,
              )
            : null,
        leading: Opacity(
          opacity: onTap != null ? 1.0 : 0.4,
          child: CircleAvatar(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            child: icon,
          ),
        ),
        trailing: trailing,
        onTap: onTap != null ? () => onTap?.call(context) : null,
        enabled: onTap != null,
      ),
    );
  }
}

class ActionListSection extends ConsumerWidget {
  final String? title;
  final List<ActionListItem> children;
  final bool fullWidth;

  const ActionListSection(
    this.title, {
    super.key,
    required this.children,
    this.fullWidth = false,
  });

  factory ActionListSection.fromMenuActions(
    BuildContext context,
    String? title, {
    Key? key,
    required List<ActionItem> actions,
    bool fullWidth = false,
  }) {
    return ActionListSection(
      title,
      key: key,
      fullWidth: fullWidth,
      children: actions.map((action) {
        final intent = action.intent;
        return ActionListItem(
          key: action.key,
          feature: action.feature,
          borderRadius: fullWidth ? 0 : null,
          actionStyle: action.actionStyle ?? ActionStyle.normal,
          icon: action.icon,
          title: action.title,
          subtitle: action.subtitle,
          onTap: intent != null
              ? (context) => Actions.invoke(context, intent)
              : null,
          trailing: action.trailing,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFeature = ref.watch(featureProvider);
    final enabledChildren = children.where(
      (item) => item.feature == null || hasFeature(item.feature!),
    );
    if (enabledChildren.isEmpty) {
      return const SizedBox();
    }
    final content = Column(
      children: [if (title != null) ListTitle(title!), ...enabledChildren],
    );
    if (fullWidth) {
      return content;
    } else {
      return SizedBox(width: 360, child: content);
    }
  }
}
