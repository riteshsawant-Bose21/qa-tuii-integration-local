import 'package:flutter/material.dart';
import 'package:fusion_app/core/extentions/gesture.dart';
import 'package:fusion_app/features/landing/presentation/widgets/recent_item_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
class RecentSearchScreen extends StatelessWidget {
  final List<String> recent;
  final Function? onClear;
  const RecentSearchScreen({super.key, required this.recent,this.onClear});

  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          if(recent.isEmpty)...[
            Text(
              "NO RECENT SEARCHES",
              style: context.textTheme.l1Medium.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.textBody,
              ),
            ),
          ]
          else
            ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RECENT SEARCHES",
                    style: context.textTheme.l1Medium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.textBody,
                    ),
                  ),
                  Text(
                    "Clear All",
                    style: context.textTheme.l1SemiBold.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.textPrimary,
                    ),
                  ).clickWidget(
                    onTap: () {
                      onClear!();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ...recent.map((e) => RecentItem(title: e)),
            ]


        ],
      ),
    );
  }
}