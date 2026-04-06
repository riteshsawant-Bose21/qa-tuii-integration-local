import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ViewToggleButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.white : context.colorScheme.elevation3.withAlpha(200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FusionIcon.icon(
          icon,
          color: isSelected ? context.colorScheme.elevation3.withAlpha(200) : context.colorScheme.white,
        ),
      ),
    );
  }
}