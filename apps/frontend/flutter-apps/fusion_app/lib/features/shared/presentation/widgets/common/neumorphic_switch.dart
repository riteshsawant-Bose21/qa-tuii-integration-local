import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class NeumorphicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeumorphicToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value
              ? context.colorScheme.primary // ON
              : context.colorScheme.textPrimary, // OFF (dark surface)
          borderRadius: BorderRadius.circular(8),
          boxShadow:  [
            // inset highlight
            BoxShadow(
              color:context.colorScheme.elevation1,
              offset: Offset(-1.5, -1.5),
              blurRadius: 3,
              spreadRadius: 0,
            ),
            // inset shadow
            BoxShadow(
              color: context.colorScheme.textPrimary,
              offset: Offset(1.5, 1.5),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? context.colorScheme.onPrimary : context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
