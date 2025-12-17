import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionRadio<T> extends StatelessWidget {
  final T? selected;
  final List<T> options;
  final ValueChanged<T>? onChanged;
  final Widget Function(T option) labelBuilder;

  const FusionRadio({
    super.key,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        ...options.map((T option) {
          final bool isSelected = selected == option;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged?.call(option),
              behavior: HitTestBehavior.translucent,
              child: Row(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16,
                    color: context.colorScheme.onSurface,
                  ),

                  labelBuilder(option),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
