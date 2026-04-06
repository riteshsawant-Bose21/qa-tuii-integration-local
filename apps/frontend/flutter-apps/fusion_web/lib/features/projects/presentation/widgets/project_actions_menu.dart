import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class ProjectActionsMenu extends StatelessWidget {
  final VoidCallback onInvite;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const ProjectActionsMenu({
    super.key,
    required this.onInvite,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: context.colorScheme.elevation3,
      // icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'invite':
            onInvite();
            break;
          case 'archive':
            onArchive();
            break;
          case 'delete':
            onDelete();
            break;
          case 'transfer ownership':
            // Handle transfer ownership action
            break;
          case 'move project':
            // Handle move project action
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'transfer ownership',
          child: Row(
            children: [
              FusionIcon.icon(Icons.file_copy, size: 16),
              const SizedBox(width: 8),
              const FusionAppText(text: 'Transfer Ownership'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'move project',
          child: Row(
            children: [
              FusionIcon.icon(Icons.drive_file_move_outlined, size: 16),
              const SizedBox(width: 8),
              const FusionAppText(text: 'Move Project'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'invite',
          child: Row(
            children: [
              FusionIcon.icon(Icons.person_add_outlined, size: 16),
              const SizedBox(width: 8),
              const FusionAppText(text: 'Invite User'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              FusionIcon.icon(Icons.archive_outlined, size: 16),
              const SizedBox(width: 8),
              const FusionAppText(text: 'Archive'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              FusionIcon.icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const FusionAppText(
                text: 'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        
      ],
    );
  }
}
