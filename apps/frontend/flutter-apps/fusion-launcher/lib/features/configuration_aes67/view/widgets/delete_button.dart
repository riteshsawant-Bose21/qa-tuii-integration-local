import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// Delete button for table rows
class DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  const DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDelete,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FusionIcon.icon(
          semanticId: 'aes67_delete_button',
          Icons.delete_outline,
          size: 18,
          color: context.colorScheme.textSecondary,
        ),
      ),
    );
  }
}
