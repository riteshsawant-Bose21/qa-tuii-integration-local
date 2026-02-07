import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final Function()? onViewAll;

  const DashboardSectionHeader({super.key, required this.title, this.showViewAll = false, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: title,
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textBody,
                fontSize: 12,
              ),
            ),
            if (showViewAll)
              InkWell(
                onTap: onViewAll,
                child: FusionAppText(
                  text: "View All",
                  style: context.textTheme.labelSmall!.copyWith(
                    color: context.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 5),
        Divider(
          color: context.colorScheme.elevation2,
          thickness: 1,
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
