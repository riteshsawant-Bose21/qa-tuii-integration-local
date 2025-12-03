import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/constants/assets_constants.dart';

class SnapshotItemCard extends StatefulWidget {
  final SceneModel snapShotData;
  final bool isDragging;
  final bool isSelected;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SnapshotItemCard({
    this.isDragging = false,
    this.isSelected = false,
    super.key,
    required this.snapShotData,
    this.onDelete,
    this.onTap, // Add this
  });

  @override
  State<SnapshotItemCard> createState() => _SnapshotItemCardState();
}

class _SnapshotItemCardState extends State<SnapshotItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
          }
        },

        /// Card container
        child: Container(
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? Colors.grey[200]
                    : widget.isDragging
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                    : (_isHovered ? Colors.grey[200] : null),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.isSelected ? Theme.of(context).colorScheme.greyDark : (widget.isDragging ? Theme.of(context).colorScheme.primary : Colors.transparent),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              /// draggable icon
              Opacity(
                opacity: 0.4,
                child: Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              const FusionImage.asset(
                Assets.playIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FusionAppText(
                  text: widget.snapShotData.name,
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ),

              const SizedBox(width: 8),
              if (!widget.isDragging)
                Tooltip(
                  message: 'Delete Snapshot',
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onDelete != null) {
                        widget.onDelete!();
                      }
                    },
                    child: const FusionImage.asset(
                      Assets.deleteIcon,
                      width: 17,
                      height: 17,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
