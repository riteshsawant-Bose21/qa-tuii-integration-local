import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/snapshots/SnapshotsKeys.dart';
import 'package:fusion_lib/fusion_lib.dart';
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
      selected: widget.isSelected,
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
                      ? context.colorScheme.elevation3
                      : widget.isDragging
                      ? context.colorScheme.primary.withAlpha(150)
                      : (_isHovered ? context.colorScheme.elevation2 : null),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected ? context.colorScheme.elevation5 : (widget.isDragging ? context.colorScheme.primary : Colors.transparent),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: <Widget>[
                /// snapshot item draggable icon
                ReorderableDragStartListener(
                  index: widget.index,
                  child: FusionIcon.icon(
                    semanticId: "${FusionTestKeys.instance.snplistitmdragindicator}_${widget.index}",
                    Icons.drag_indicator,
                    size: 16,
                    color: context.colorScheme.textPlaceholder,
                  ),
                ),
                const SizedBox(width: 8),
                FusionImage.asset(
                  semanticId: "${FusionTestKeys.instance.snplistitmplayicon}_${widget.index}",
                  Assets.playIcon,
                  width: 24,
                  height: 24,
                  assetColor: context.colorScheme.iconWhite,
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
                                  semanticId: SemanticHelper.createTestId(SemanticTypes.card, "delete_snapshot_${widget.index}"),
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
                        child: FusionImage.asset(
                          semanticId: "${FusionTestKeys.instance.snplistitmdeleteicon}_${widget.index}",
                          Assets.deleteIcon,
                          width: 17,
                          height: 17,
                          assetColor: context.colorScheme.iconWhite,
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
                        child: FusionImage.asset(
                          semanticId: "${FusionTestKeys.instance.snplistitmduplicateicon}_${widget.index}",
                          Assets.duplicateIcon,
                          width: 16,
                          height: 16,
                          assetColor: context.colorScheme.iconWhite,
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
