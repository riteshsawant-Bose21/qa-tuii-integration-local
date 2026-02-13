import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const FusionCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? Colors.grey[600] : Colors.transparent, // Muted check color
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.grey,
                width: 1.5,
              ),
            ),
            child:
                value
                    ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                    : null,
          ),
          const SizedBox(width: 10),
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
