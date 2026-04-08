import 'package:flutter/material.dart';
import 'package:fusion_app/features/control_pal/models/control_pal_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NavItem extends StatelessWidget {
  final BottomNavItemModel item;
  final bool selected;

  const NavItem({super.key,
    required this.item,
    this.selected=false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colorScheme.primary
        : context.colorScheme.textBody;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: color),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: context.textTheme.l2Medium!.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.textBody,
          ),
        ),
      ],
    );
  }
}