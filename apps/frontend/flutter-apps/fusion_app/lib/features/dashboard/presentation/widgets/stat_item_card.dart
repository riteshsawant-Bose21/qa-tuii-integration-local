import 'package:flutter/material.dart';
import 'package:fusion_app/features/dashboard/presentation/widgets/section_stats.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DashStatCard extends StatelessWidget {
  final StatsCardModel data;
  const DashStatCard({super.key, required this.data});

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
          CommonCircleIcon(
            icon: data.icon,
            iconColor: context.colorScheme.iconWhite,
            bgColor: context.colorScheme.elevation2,
          ),
          SizedBox(height: 16),
          Text(data.title, style: context.textTheme.b3Regular.copyWith(
              color: context.colorScheme.textSecondary,
              fontWeight: FontWeight.w400
          ),),
          const SizedBox(height: 12),
          Text(
            data.value.toString(),
            style: context.textTheme.h3BoldMobile.copyWith(
              color: context.colorScheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 32
            ),
          )
        ],
      ),
    );
  }
}
