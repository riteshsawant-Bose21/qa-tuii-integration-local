import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FusionSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;
  final double width;

  const FusionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 12,
    this.width = 30,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: FittedBox(
        fit: BoxFit.cover,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return context.colorScheme.white;
            }
            return context.colorScheme.greyDark;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return context.colorScheme.greyDark;
            }
            return context.colorScheme.grey;
          }),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}
