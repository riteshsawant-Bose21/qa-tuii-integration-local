// ─────────────────────────────────────────────────────────────
// 5. FusionIconTextButton
//
// A leading icon + label row used for "+ Add …" type actions.
//
// Usage:
//   FusionIconTextButton(
//     icon: LucideIcons.plus,
//     label: 'Add SubZones',
//     semanticId: 'add_subzones',
//     onTap: _enterSetupMode,
//   )
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class FusionIconTextButton extends StatefulWidget {
  const FusionIconTextButton({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticId,
    required this.onTap,
    this.iconSize = 14,
    this.spacing = 5,
    this.style,
    this.iconColor,
    this.hoverColor,
  });

  final IconData icon;
  final String label;
  final String semanticId;
  final VoidCallback onTap;
  final double iconSize;
  final double spacing;

  /// Base text style. Defaults to bodySmall in onSurface.
  final TextStyle? style;

  /// Base icon colour. Defaults to colorScheme.primaryWhite.
  final Color? iconColor;

  /// Hover colour applied to both icon and text.
  final Color? hoverColor;

  @override
  State<FusionIconTextButton> createState() => _FusionIconTextButtonState();
}

class _FusionIconTextButtonState extends State<FusionIconTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color baseIconColor = widget.iconColor ?? context.colorScheme.primaryWhite;
    final Color baseTextColor = (widget.style?.color) ?? context.colorScheme.onSurface;
    final Color hover = widget.hoverColor ?? context.colorScheme.elevation6;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, widget.semanticId),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: widget.iconSize,
                color: _hovered ? hover : baseIconColor,
              ),
              SizedBox(width: widget.spacing),
              FusionAppText(
                text: widget.label,
                style: (widget.style ?? context.textTheme.bodySmall?.copyWith(color: baseTextColor))?.copyWith(color: _hovered ? hover : baseTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
