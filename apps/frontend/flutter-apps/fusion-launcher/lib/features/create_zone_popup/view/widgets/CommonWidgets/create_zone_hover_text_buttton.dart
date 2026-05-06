// ─────────────────────────────────────────────────────────────
// 4. FusionHoverTextButton
//
// A plain-text tap target that transitions between two colours
// on hover. Replaces the repeated MouseRegion + GestureDetector
// + FusionAppText pattern.
//
// Usage:
//   FusionHoverTextButton(
//     label: 'Cancel',
//     semanticId: 'subzone_cancel',
//     onTap: _exitSetupMode,
//   )
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionHoverTextButton extends StatefulWidget {
  const FusionHoverTextButton({
    super.key,
    required this.label,
    required this.semanticId,
    required this.onTap,
    this.style,
    this.hoverColor,
  });

  final String label;
  final String semanticId;
  final VoidCallback onTap;

  /// Base text style. Defaults to l1SemiBold in textPrimary.
  final TextStyle? style;

  /// Colour when hovered. Defaults to colorScheme.elevation6.
  final Color? hoverColor;

  @override
  State<FusionHoverTextButton> createState() => _FusionHoverTextButtonState();
}

class _FusionHoverTextButtonState extends State<FusionHoverTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = widget.style ?? context.textTheme.l1SemiBold.copyWith(color: context.colorScheme.textPrimary);

    final Color hoverColor = widget.hoverColor ?? context.colorScheme.elevation6;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, widget.semanticId),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: FusionAppText(
            text: widget.label,
            style: base.copyWith(color: _hovered ? hoverColor : base.color),
          ),
        ),
      ),
    );
  }
}
