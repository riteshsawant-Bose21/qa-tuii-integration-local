import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceDetailsTab extends StatelessWidget {
  final String label;
  final int index;
  final TabController tabController;

  const DeviceDetailsTab({
    super.key,
    required this.label,
    required this.index,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (BuildContext context, _) {
        final bool isSelected = tabController.index == index;
        return GestureDetector(
          onTap: () => tabController.animateTo(index),
          child: Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.circular(6),
              border:
                  isSelected
                      ? Border(
                        bottom: BorderSide(color: context.colorScheme.primary, width: 2),
                      )
                      : null,
            ),
            child: FusionAppText(
              text: label,
              style: context.textTheme.labelMedium!.copyWith(
                color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
