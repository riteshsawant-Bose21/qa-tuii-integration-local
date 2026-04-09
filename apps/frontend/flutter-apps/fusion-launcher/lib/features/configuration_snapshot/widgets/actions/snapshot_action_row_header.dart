import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/snapshots/SnapshotsKeys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class SnapshotActionRowHeader extends StatelessWidget {
  const SnapshotActionRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.actionlistpanelrowheader),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: context.colorScheme.elevation2.withAlpha(120),
        child: Row(
          spacing: 12,

          children: <Widget>[
            const SizedBox(width: 30),
            _HeaderCell(semanticId: FusionTestKeys.instance.actionlistpanelrowheaderactiontype, text: "Action Type"),

            _HeaderCell(semanticId: FusionTestKeys.instance.actionlistpanelrowheaderactionitm, text: "Action Item"),

            _HeaderCell(semanticId: FusionTestKeys.instance.actionlistpanelrowheaderaction, text: "Param / Action"),

            _HeaderCell(semanticId: FusionTestKeys.instance.actionlistpanelrowheadervalue, text: "Value"),
            const SizedBox(width: 46),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final String? semanticId;

  const _HeaderCell({required this.text, required this.semanticId});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FusionAppText(
        semanticId: semanticId,
        text: text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Theme.of(context).colorScheme.textPrimary,
        ),
        maxLine: 1,
      ),
    );
  }
}
