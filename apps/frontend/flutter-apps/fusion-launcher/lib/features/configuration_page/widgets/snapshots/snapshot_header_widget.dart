import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class SnapshotHeaderWidget extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onReorder;

  const SnapshotHeaderWidget({
    super.key,
    required this.onAdd,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.greyLight,
        // border bottom
        border: Border(
          bottom: BorderSide(width: 1, color: context.colorScheme.grey),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.layers, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: FusionAppText(
              text: "Snapshots",
              style: context.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              maxLine: 1,
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Icon(Icons.add, size: 16),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onReorder,
            child: const Icon(Icons.more_vert, size: 16),
          ),
        ],
      ),
    );
  }
}
