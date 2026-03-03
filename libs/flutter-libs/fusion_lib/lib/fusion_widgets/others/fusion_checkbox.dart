import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionCheckbox extends StatelessWidget {
  final bool? value;
  final VoidCallback onChanged;
  final double iconSize;
  final bool enabled;
  final String semanticId;

  const FusionCheckbox({
    super.key,
    this.value,
    required this.semanticId,
    required this.onChanged,
    this.iconSize = 16,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == true;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "fusion_checkbox${semanticId ?? ''}",
      ),
      isActive: enabled,
      selected: value,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: enabled ? () => onChanged() : null,
          child: Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? context.colorScheme.primaryColor : null,
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : context.colorScheme.iconDisabled,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 10,
              color: isActive ? Colors.white : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
