import 'package:flutter/material.dart';

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

  /// Creates a [FusionDialog].
  const FusionDialog({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: roundedCorners ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)) : null,
      backgroundColor: backgroundColor ?? Theme.of(context).dialogBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 48, color: iconColor ?? Theme.of(context).primaryColor), const SizedBox(height: 16)],
              Text(title, textAlign: TextAlign.center, style: titleTextStyle ?? Theme.of(context).textTheme.headlineSmall),
              if (description != null) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(description!, textAlign: TextAlign.center, style: descriptionTextStyle ?? Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondaryButtonLabel != null && onSecondaryPressed != null) ...[
                    TextButton(onPressed: onSecondaryPressed, child: Text(secondaryButtonLabel!)),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(onPressed: onPrimaryPressed, child: Text(primaryButtonLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
