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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colorScheme.elevation1,
        ),
        child: icon != null
            ? Icon(icon, color: context.colorScheme.iconWhite)
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