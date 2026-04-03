import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

/// Standard table cell text
class CellText extends StatelessWidget {
  final String text;
  final bool bold;
  final BuildContext context;

  const CellText({
    required this.text,
    required this.context,
    this.bold = false,
  });

  @override
  Widget build(BuildContext _) {
    final String displayText = text.isEmpty ? '-' : text;
    return FusionAppText(
      semanticId: 'aes67_cell_text',
      text: displayText,
      maxLine: 1,
      textOverflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: bold ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
      ),
    );
  }
}
