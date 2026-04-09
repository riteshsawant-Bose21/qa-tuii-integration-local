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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.elevation2
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.colorScheme.strokeLight,
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
                    style: Theme.of(context).textTheme.b3Medium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.l1Regular!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.textBody,
                    ),
                  ),
                ],
              ),
            ),

            /// Radio / Check
           Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ?  context.colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected ? null : Border.all(
                  color: context.colorScheme.iconDefault,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.check,
                color: context.colorScheme.primaryBlack,
                size: 12,
              ),
            )
          ],
        ),
      ),
    );
  }
}