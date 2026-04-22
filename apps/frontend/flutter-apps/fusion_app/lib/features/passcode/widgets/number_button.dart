import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class NumberButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const NumberButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 12),
      child: ElevatedButton(
        onPressed: onTap, // pass your callback
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          elevation: 0,
          backgroundColor: context.colorScheme.elevation1,
          shape: const CircleBorder(),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
              if (states.contains(WidgetState.pressed)) {
                return context.colorScheme.elevation3;
              }
              return null;
            },
          ),
          animationDuration: const Duration(milliseconds: 120),
        ),
        child: icon != null
            ? Icon(
          icon,
          color: context.colorScheme.iconWhite,
        )
            : Text(
          label!,
          style: Theme.of(context).textTheme.h4RegularMobile!.copyWith(
            fontWeight: FontWeight.w400,
            color: context.colorScheme.textPrimary,
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}