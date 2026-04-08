import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MenuItem extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool showTrailingIcon;
  final Function? onTap;
  const MenuItem({required this.title,
    required this.icon,
    this.showTrailingIcon=true,
    required this.onTap,super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if(icon!=null)
            Icon(icon, color:context.colorScheme.iconWhite),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.b2Regular!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ),
            if (showTrailingIcon)
               Icon(
                Icons.chevron_right,
                size: 24,
                color: context.colorScheme.iconDefault,
              ),
          ],
        ),
      ),
    );
  }
}

class MenuItemModel {
  final IconData icon;
  final String title;
  final bool showTrailingIcon;
  final VoidCallback onTap;

  const MenuItemModel({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showTrailingIcon = true,
  });
}
