import 'package:flutter/material.dart';
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
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
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
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'invite',
          child: Row(
            children: [
              Icon(Icons.person_add_outlined, size: 16),
              SizedBox(width: 8),
              FusionAppText(text:'Invite User'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 16),
              SizedBox(width: 8),
              FusionAppText(text:'Archive'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              FusionAppText(text:'Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

