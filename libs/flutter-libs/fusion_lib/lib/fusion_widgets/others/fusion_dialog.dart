import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A customizable and reusable dialog for the Fusion design system.
///
/// The [FusionDialog] provides a consistent way to display messages,
/// alerts, confirmations, or custom content with the Fusion UI style.
///
/// It supports:
/// - Custom title and description
/// - Optional leading icon
/// - Primary and secondary action buttons
/// - Scrollable content area for large text
/// - Full styling control
///
/// ### Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => FusionDialog(
///     title: 'Delete Project',
///     description: 'Are you sure you want to delete this project? This action cannot be undone.',
///     icon: Icons.warning,
///     iconColor: Colors.red,
///     primaryButtonLabel: 'Delete',
///     onPrimaryPressed: () {
///       // Handle delete
///     },
///     secondaryButtonLabel: 'Cancel',
///     onSecondaryPressed: () => Navigator.pop(context),
///   ),
/// );
/// ```
class FusionDialog extends StatelessWidget {
  /// Title text displayed at the top of the dialog.
  final String title;

  /// Description or body text displayed below the title.
  final String? description;

  /// Optional icon displayed above the title.
  final IconData? icon;

  /// Color of the [icon] if provided.
  final Color? iconColor;

  /// Label for the primary action button.
  final String primaryButtonLabel;

  /// Callback triggered when the primary button is pressed.
  final VoidCallback onPrimaryPressed;

  /// Label for the secondary action button (optional).
  final String? secondaryButtonLabel;

  /// Callback triggered when the secondary button is pressed (optional).
  final VoidCallback? onSecondaryPressed;

  /// Whether to show the dialog with rounded corners. Default is `true`.
  final bool roundedCorners;

  /// Border radius for rounded corners. Default is `12`.
  final double borderRadius;

  /// Dialog background color. Defaults to [Theme.dialogBackgroundColor].
  final Color? backgroundColor;

  /// Title text style. Defaults to `headlineSmall` from the theme.
  final TextStyle? titleTextStyle;

  /// Description text style. Defaults to `bodyMedium` from the theme.
  final TextStyle? descriptionTextStyle;

  final double primaryButtonWidth;
  final Color? primaryButtonColor;

  final String? semanticId;

  /// Creates a [FusionDialog].
  const FusionDialog({
    super.key,
    this.semanticId,
    required this.title,
    this.description,
    this.icon,
    this.iconColor,
    required this.primaryButtonLabel,
    required this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.roundedCorners = true,
    this.borderRadius = 12,
    this.backgroundColor,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.primaryButtonWidth = 90,
    this.primaryButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "fusion_dialog_${semanticId ?? ""}",
      ),
      child: Dialog(
        shape: roundedCorners
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              )
            : null,
        backgroundColor: backgroundColor ?? context.colorScheme.elevation1,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),

        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 50),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 48,
                      color:
                          iconColor ??
                          Theme.of(context).colorScheme.primaryWhite,
                    ),
                    const SizedBox(height: 16),
                  ],
                  FusionAppText(
                    text: title,
                    textAlign: TextAlign.center,
                    style:
                        titleTextStyle ??
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: FusionAppText(
                          text: description!,
                          textAlign: TextAlign.center,
                          style:
                              descriptionTextStyle ??
                              Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (secondaryButtonLabel != null &&
                          onSecondaryPressed != null) ...[
                        SizedBox(
                          width: 90,
                          child: FusionAppButton(
                            semanticId: 'dialog_box',
                            text: secondaryButtonLabel!,
                            style: FusionAppButtonStyle.secondary,
                            onPressed: () {
                              onSecondaryPressed?.call();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: primaryButtonWidth,
                        child: FusionAppButton(
                          semanticId: 'dialog_box',
                          text: primaryButtonLabel,
                          style: FusionAppButtonStyle.primary,
                          enabled: true,
                          onPressed: () {
                            onPrimaryPressed.call();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
