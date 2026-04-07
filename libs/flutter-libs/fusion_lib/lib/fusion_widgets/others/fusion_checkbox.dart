import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionCheckbox extends StatelessWidget {
  final bool? value;
  final VoidCallback onChanged;
  final double iconSize;
  final bool enabled;
  final String semanticId;
  final BoxShape? shape;
  final double height;
  final double width;

  const FusionCheckbox({
    super.key,
    this.height = 16,
    this.width = 16,
    this.shape,
    this.value,
    required this.semanticId,
    required this.onChanged,
    this.iconSize = 16,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == true;
    final resolvedShape = shape ?? BoxShape.rectangle;

    return SemanticHelper.toggle(
      testId: SemanticHelper.createTestId(
        SemanticTypes.toggle,
        "fusion_checkbox${semanticId ?? ''}",
      ),
      value: isActive,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,

        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: enabled ? () => onChanged() : null,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              shape: resolvedShape,
              borderRadius: resolvedShape == BoxShape.rectangle ? BorderRadius.circular(4) : null,
              color: resolvedShape == BoxShape.circle ? Colors.transparent : (isActive ? context.colorScheme.iconWhite : null),
              border: Border.all(
                color: isActive ? context.colorScheme.iconWhite : context.colorScheme.iconDisabled,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive
                  ? (resolvedShape == BoxShape.circle
                        ? Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colorScheme.iconWhite,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            size: 10,
                            color: context.colorScheme.black,
                          ))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
