import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class SnapshotActionRowHeader extends StatelessWidget {
  const SnapshotActionRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.grey.withAlpha(40),
      child: const Row(
        children: <Widget>[
          SizedBox(width: 30),
          _HeaderCell("Action Type"),
          SizedBox(width: 16),

          _HeaderCell("Action Item"),
          SizedBox(width: 16),

          _HeaderCell("Param / Action"),
          SizedBox(width: 16),

          _HeaderCell("Value"),
          SizedBox(width: 64),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FusionAppText(
        text: text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Theme.of(context).colorScheme.fusionTextViewColor,
        ),
        maxLine: 1,
      ),
    );
  }
}
