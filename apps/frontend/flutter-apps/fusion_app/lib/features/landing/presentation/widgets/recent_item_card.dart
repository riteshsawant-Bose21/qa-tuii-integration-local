import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class RecentItem extends StatelessWidget {
  final String title;

  const RecentItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.history,
              size: 20,
              color: context.colorScheme.textSecondary),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.b3Regular.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}