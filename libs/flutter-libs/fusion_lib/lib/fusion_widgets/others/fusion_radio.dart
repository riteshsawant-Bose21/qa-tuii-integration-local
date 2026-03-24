import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionRadio<T> extends StatelessWidget {
  final T? selected;
  final List<T> options;
  final ValueChanged<T>? onChanged;
  final Widget Function(T option) labelBuilder;
  final String? semanticId;

  const FusionRadio({
    this.semanticId,
    super.key,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "fusion_radio_${semanticId ?? ""}",
      ),
      child: Wrap(
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
                  spacing: 10,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
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
      ),
    );
  }
}
