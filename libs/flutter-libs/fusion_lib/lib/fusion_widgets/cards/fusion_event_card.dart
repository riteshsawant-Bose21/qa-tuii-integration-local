import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionEventCard extends StatelessWidget {
  final String label;
  final String description;
  final String? time;
  final Color color;
  final double? width;
  final double? height;

  final VoidCallback? onEdit;
  final VoidCallback? onRunNow;
  final VoidCallback? onCancel;

  final String semanticId;

  const FusionEventCard({
    super.key,
    required this.label,
    required this.description,
    this.time,
    required this.color,
    required this.onEdit,
    required this.onRunNow,
    required this.onCancel,
    this.width,
    this.height,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.card,
        'fusion_event_card${semanticId}',
      ),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FusionDarkColorPallette.dark80,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: context.colorScheme.primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: context.colorScheme.primaryWhite,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                if (onEdit != null)
                  FusionNeumorphicButton(
                    semanticId: 'fusion_event_card_edit_button',
                    onTap: () => onEdit!.call(),
                    borderRadius: 6,
                    width: 40,
                    child: const Icon(Icons.edit, size: 18),
                  ),
              ],
            ),

            if (time != null) ...[
              const SizedBox(height: 8),
              Text(
                time!,
                style: const TextStyle(
                  color: FusionDarkColorPallette.medium50,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
            if (onRunNow != null || onCancel != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onRunNow != null)
                    FusionNeumorphicButton(
                      semanticId: 'fusion_event_card_run_now_button',
                      text: 'Run Now',
                      onTap: () => onRunNow!.call(),
                      width: 90,
                      borderRadius: 8,
                    ),

                  if (onCancel != null)
                    FusionTextButton(
                      accessLabel: 'fusion_event_card_cancel_button',
                      onTap: () => onCancel!.call(),
                      label: "Cancel",
                      width: 100,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
