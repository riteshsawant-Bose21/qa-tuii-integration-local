import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionRadioButton<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T?> onChanged;

  const FusionRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Custom Radio Circle
          Container(
            width: 18,
            height: 18,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child:
                isSelected
                    ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 8),
          FusionAppText(
            text: label,
            style: context.textTheme.labelMedium!.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
