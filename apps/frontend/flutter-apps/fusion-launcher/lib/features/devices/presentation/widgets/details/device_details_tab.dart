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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? context.colorScheme.elevation3 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.transparent, // Clean look
              ),
            ),
            child: FusionAppText(
              text: label,
              style: context.textTheme.labelMedium!.copyWith(
                color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
