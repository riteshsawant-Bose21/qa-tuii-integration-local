import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/snapshot_item_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A widget that displays a list of snapshot items in a reorderable list view.
/// It takes a list of [SnapshotsModel] objects and an optional background color.
/// The list view is non-scrollable and adapts its background color based on the provided color or defaults to a light grey with some transparency.
///
/// Example usage:
/// ```dart
/// SnapShotItemList(
///  snapShotList: mySnapshotList,
///  backgroundColor: Colors.white,
///  onReorder: (oldIndex, newIndex) { /* handle reorder */ },
///  );
/// ```
///
/// Parameters:
/// - [snapShotList]: A required list of [SnapshotsModel] objects to be displayed.
/// - [backgroundColor]: An optional color for the background of the list.
/// - [onReorder]: Callback function to handle reordering of items.
/// /// Returns:
/// A [Container] widget containing a [ReorderableListView] of snapshot items.

class SnapshotList extends StatelessWidget {
  final List<SnapshotsModel> snapShotList;
  final Color? backgroundColor;
  final Function(String sceneId) onDelete;
  final Function(String sceneId)? onSelect;
  final Function(String sceneId)? onDuplicate;
  final String? selectedSnapshotId;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String sceneId)? onDragStarted;
  final VoidCallback? onDragEnd;
  final String? draggingSnapshotId;
  final void Function(String value, SnapshotsModel newSnapshot)? onRenameSave;

  const SnapshotList({
    super.key,
    this.backgroundColor,
    required this.snapShotList,
    required this.onDelete,
    this.onSelect,
    this.onDuplicate,
    this.selectedSnapshotId,
    this.onReorder,
    this.onDragStarted,
    this.onDragEnd,
    this.draggingSnapshotId,
    this.onRenameSave,
  });

  @override
  Widget build(BuildContext context) {
    if (snapShotList.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return FadeTransition(
          opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        );
      },
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapShotList.length,
      onReorder: (int oldIndex, int newIndex) {
        if (onReorder != null) {
          onReorder!(oldIndex, newIndex);
        }
      },
      itemBuilder: (BuildContext context, int index) {
        final SnapshotsModel snapShotData = snapShotList[index];
        final bool isDragging = draggingSnapshotId == snapShotData.id;

        return Container(
          key: ValueKey<String>(snapShotData.id),
          margin: const EdgeInsets.only(bottom: 4),
          child: Draggable<SnapshotsModel>(
            data: snapShotData,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: () {
              if (onDragStarted != null) {
                onDragStarted!(snapShotData.id);
              }
            },
            onDraggableCanceled: (_, __) {
              if (onDragEnd != null) {
                onDragEnd!();
              }
            },
            onDragEnd: (_) {
              if (onDragEnd != null) {
                onDragEnd!();
              }
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 220,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  maxHeight: 36,
                ),
                child: Opacity(
                  opacity: 0.8,
                  child: SnapshotItemCard(
                    index: index,
                    snapShotData: snapShotData,
                    isDragging: true,
                    isSelected: selectedSnapshotId == snapShotData.id,
                    onDelete: () {
                      onDelete(snapShotData.id);
                    },
                    onTap: () {
                      if (onSelect != null) {
                        onSelect!(snapShotData.id);
                      }
                    },
                    onDuplicate: () {
                      if (onDuplicate != null) {
                        onDuplicate!(snapShotData.id);
                      }
                    },
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: SnapshotItemCard(
                index: index,
                snapShotData: snapShotData,
                isDragging: true,
                isSelected: selectedSnapshotId == snapShotData.id,
                onDelete: () {
                  onDelete(snapShotData.id);
                },
                onTap: () {
                  if (onSelect != null) {
                    onSelect!(snapShotData.id);
                  }
                },
                onDuplicate: () {
                  if (onDuplicate != null) {
                    onDuplicate!(snapShotData.id);
                  }
                },
              ),
            ),
            child: SnapshotItemCard(
              index: index,
              snapShotData: snapShotData,
              isDragging: isDragging,
              isSelected: selectedSnapshotId == snapShotData.id,
              onRenameSave: (String value, SnapshotsModel newSnapshot) {
                if (value.isNotEmpty) {
                  if (onRenameSave != null) {
                    onRenameSave!.call(value, newSnapshot);
                  }
                }
              },
              onDelete: () {
                onDelete(snapShotData.id);
              },
              onTap: () {
                if (onSelect != null) {
                  onSelect!(snapShotData.id);
                }
              },
              onDuplicate: () {
                if (onDuplicate != null) {
                  onDuplicate!(snapShotData.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
