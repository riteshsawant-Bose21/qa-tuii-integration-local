import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PBRadio extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Size? size;
  final EdgeInsetsGeometry? padding;

  const PBRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = context.colorScheme.elevation2;
    final Color activeColor = context.colorScheme.primaryWhite;
    final Color inactiveColor = context.colorScheme.elevation5;
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "PBradio",
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double radioSize = (constraints.maxWidth * 0.3).clamp(36, 44);
          final double outerPadding = (constraints.maxWidth * 0.1).clamp(6, 8);

          return GestureDetector(
            onTap: () => onChanged.call(!value),
            child: Container(
              height: size?.height ?? radioSize,
              width: size?.width ?? radioSize,
              color: context.colorScheme.elevation1,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
                padding: padding ?? EdgeInsets.all(outerPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        value
                            ? context.colorScheme.primaryWhite
                            : context.colorScheme.strokeLight,
                  ),
                ),
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        value
                            ? context.colorScheme.primaryWhite
                            : context.colorScheme.elevation1,
                  ),
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            value
                                ? context.colorScheme.primaryWhite
                                : context.colorScheme.elevation1,
                        border: Border.all(
                          color: context.colorScheme.strokeLight,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
