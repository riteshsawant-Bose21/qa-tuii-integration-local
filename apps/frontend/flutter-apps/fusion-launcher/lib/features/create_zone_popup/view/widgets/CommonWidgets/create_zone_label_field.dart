// ─────────────────────────────────────────────────────────────
// 2. FusionLabeledField
//
// Wraps any child with an optional label above and consistent spacing.
//
// Usage:
//   FusionLabeledField(
//     label: 'Floor Name',
//     semanticId: 'floor_name',
//     child: FusionBorderedTextField(...),
//   )
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionLabeledField extends StatelessWidget {
  const FusionLabeledField({
    super.key,
    required this.child,
    required this.semanticId,
    this.label,
    this.spacing = 8,
  });

  final Widget child;
  final String semanticId;

  /// If null, no label is rendered.
  final String? label;

  /// Gap between label and child.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (label == null) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FusionAppText(
          semanticId: '${semanticId}_label',
          text: label!,
          style: Theme.of(context).textTheme.l1Medium.withColor(context.colorScheme.textPrimary),
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}
