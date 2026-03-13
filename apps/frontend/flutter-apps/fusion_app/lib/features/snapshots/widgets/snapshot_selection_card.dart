import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class SnapshotSelectionCard extends StatelessWidget {
  final String title;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SnapshotSelectionCard({
    super.key,
    required this.title,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.elevation2
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.colorScheme.elevation2,
          ),
        ),
        child: Row(
          children: [

            /// Title + Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            /// Radio / Check
            isSelected
                ? Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colorScheme.zone1Fill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: context.colorScheme.primaryBlack,
                size: 18,
              ),
            )
                : Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.textSecondary,
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}