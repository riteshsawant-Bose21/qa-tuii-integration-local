import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Header widget for the controllers sidebar
class ControllersSidebarHeader extends StatelessWidget {
  final VoidCallback? onAddController;

  const ControllersSidebarHeader({
    super.key,
    this.onAddController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
          bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: 'CONTROLLERS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (onAddController != null)
            GestureDetector(
              onTap: onAddController,
              child: FusionIcon.icon(
                Icons.add,
                size: 16,
                color: context.colorScheme.iconWhite,
              ),
            ),
        ],
      ),
    );
  }
}
