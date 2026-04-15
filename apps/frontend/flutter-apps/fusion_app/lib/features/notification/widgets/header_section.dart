import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NotificationHeaderSection extends StatelessWidget {
  final String title;
  final int count;
  const NotificationHeaderSection({required this.title,required this.count,super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style:Theme.of(context).textTheme.l1Regular.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.elevation2,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count.toString(),
            style:Theme.of(context).textTheme.l2Bold.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

