import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionConfirmationPopup extends StatelessWidget {
  final String title;
  final String description;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const FusionConfirmationPopup({
    super.key,
    required this.title,
    required this.description,
    this.confirmButtonText = 'Yes',
    this.cancelButtonText = 'No',
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colorScheme.elevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FusionAppText(
                    text: title.toUpperCase(),
                    style: context.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: context.colorScheme.iconWhite,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              thickness: 1,
              color: context.colorScheme.strokeLight,
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: FusionAppText(
                text: description,
                style: context.textTheme.labelMedium,
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    child: FusionAppText(
                      text: cancelButtonText,
                      style: context.textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      onConfirm();
                      Navigator.of(context).pop();
                    },
                    child: FusionContainer(
                      raised: true,
                      color: context.colorScheme.elevation1,
                      borderRadius: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FusionAppText(
                          text: confirmButtonText,
                          style: context.textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
