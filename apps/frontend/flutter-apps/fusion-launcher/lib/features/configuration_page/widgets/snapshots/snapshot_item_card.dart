import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/constants/assets_constants.dart';

class SnapshotItemCard extends StatefulWidget {
  final SnapshotsModel snapShotData;
  final bool isDragging;
  final bool isSelected;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDuplicate;
  final void Function(String value, SnapshotsModel newSnapshot)? onRenameSave;
  final int index;

  const SnapshotItemCard({
    this.isDragging = false,
    this.isSelected = false,
    super.key,
    required this.snapShotData,
    this.onDelete,
    this.onTap,
    this.onDuplicate,
    required this.index,
    this.onRenameSave,
  });

  @override
  State<SnapshotItemCard> createState() => _SnapshotItemCardState();
}

class _SnapshotItemCardState extends State<SnapshotItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_item_${widget.index}"),
      child: GestureDetector(
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
                    widget.isSelected
                        ? Theme.of(context).colorScheme.greyDark
                        : (widget.isDragging ? Theme.of(context).colorScheme.primary : Colors.transparent),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: <Widget>[
                /// snapshot item draggable icon
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Opacity(
                    opacity: 0.4,
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.grey[600],
                    ),
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

                /// Snapshot name with edit capability
                Expanded(
                  child: TitleTextFieldSwitcher(
                    value: widget.snapShotData.name,
                    hintText: "Enter snapshot name",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
                    save: (String value) {
                      if (value.isNotEmpty) {
                        if (widget.onRenameSave != null) {
                          final SnapshotsModel newSnapshot = widget.snapShotData.copyWith(name: value);
                          widget.onRenameSave!.call(value, newSnapshot);
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),
                if (!widget.isDragging) ...<Widget>[
                  Tooltip(
                    message: 'Delete Snapshot',
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_snapshot_${widget.index}"),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => FusionDialog(
                                  title: 'Delete Snapshot?',
                                  description: "This will remove '${widget.snapShotData.name}' from the Snapshot list.",
                                  primaryButtonLabel: 'Delete',
                                  secondaryButtonLabel: 'Cancel',
                                  onSecondaryPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  onPrimaryPressed: () {
                                    if (widget.onDelete != null) {
                                      widget.onDelete!();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                          );
                        },
                        child: const FusionImage.asset(
                          Assets.deleteIcon,
                          width: 17,
                          height: 17,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Duplicate Snapshot',
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "duplicate_snapshot_${widget.index}"),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onDuplicate != null) {
                            widget.onDuplicate!();
                          }
                        },
                        child: const FusionImage.asset(
                          Assets.duplicateIcon,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
