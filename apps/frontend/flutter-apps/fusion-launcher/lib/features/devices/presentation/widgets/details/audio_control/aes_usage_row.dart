import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class AesUsageRow extends StatelessWidget {
  final String label;
  final int activeCount;

  const AesUsageRow({
    required this.label,
    required this.activeCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 40,
          child: FusionAppText(
            text: label,
            style: context.textTheme.labelMedium!,
          ),
        ),
        Expanded(
          child: Wrap(
            runAlignment: WrapAlignment.spaceEvenly,
            children: List<Widget>.generate(8, (int index) {
              final bool isActive = index < activeCount;
              return Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? context.colorScheme.primaryWhite : Colors.transparent, // Active White, Inactive Transparent
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.strokeDark), // Grey border for inactive
                ),
                child: FusionAppText(
                  text: "${index + 1}",
                  style: context.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? context.colorScheme.primaryBlack : context.colorScheme.textGrey,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            FusionAppText(
              text: activeCount.toString().padLeft(2, '0'),
              style: context.textTheme.titleLarge!,
            ),
            const SizedBox(width: 4),
            FusionAppText(
              text: "/8 Channels",
              style: context.textTheme.labelMedium!.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
