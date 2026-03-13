import 'package:flutter/material.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/section_stats.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SnapshotCard extends StatelessWidget {
  final String title;
  const SnapshotCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border.all(color: context.colorScheme.elevation2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommonCircleIcon(
                icon: Icons.list_alt_outlined,
                iconColor: context.colorScheme.iconWhite,
                bgColor: context.colorScheme.elevation2,
              ),
              Spacer(),
              Expanded(
                child: CommonCircleIcon(
                  icon: Icons.arrow_outward,
                  iconColor: context.colorScheme.textDisabled,
                  bgColor: context.colorScheme.iconWhite,
                )
              )
            ],
          ),
          SizedBox(height: 16),
          Text(title, style: context.textTheme.b3Regular.copyWith(
              color: context.colorScheme.textSecondary,
              fontWeight: FontWeight.w400
          ),),

        ],
      ),
    );
  }
}
