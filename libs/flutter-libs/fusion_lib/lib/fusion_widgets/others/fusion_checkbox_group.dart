import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionCheckboxGroup<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selected;

  /// Builders
  final Widget Function(BuildContext context, T option) labelBuilder;

  /// Callbacks
  final ValueChanged<List<T>>? onChanged;

  /// Layout
  final double spacing;
  final double runSpacing;
  final Axis direction;

  /// Icon
  final double iconSize;

  /// Style
  final TextStyle? labelStyle;

  /// Interaction
  final bool enabled;

  const FusionCheckboxGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    this.onChanged,
    this.spacing = 10,
    this.runSpacing = 10,
    this.direction = Axis.horizontal,
    this.iconSize = 16,
    this.labelStyle,
    this.enabled = true,
  });

  void onClick(isSelected, option) {
    final List<T> updated = List<T>.from(selected);

    if (isSelected) {
      updated.remove(option);
    } else {
      updated.add(option);
    }

    onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      direction: direction,
      children: options.map((T option) {
        final bool isSelected = selected.contains(option);

        return MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: enabled ? () => onClick(isSelected, option) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: <Widget>[
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: iconSize,
                  color: context.colorScheme.onSurface,
                ),
                DefaultTextStyle.merge(
                  style: labelStyle ?? Theme.of(context).textTheme.bodySmall,
                  child: labelBuilder(context, option),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
