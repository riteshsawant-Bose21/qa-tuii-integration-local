import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_item_card.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

/// A widget that displays a list of snapshot items in a reorderable list view.
/// It takes a list of [SceneModel] objects and an optional background color.
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
/// - [snapShotList]: A required list of [SceneModel] objects to be displayed.
/// - [backgroundColor]: An optional color for the background of the list.
/// - [onReorder]: Callback function to handle reordering of items.
/// /// Returns:
/// A [Container] widget containing a [ReorderableListView] of snapshot items.

class SnapshotList extends StatelessWidget {
  final List<SceneModel> snapShotList;
  final Color? backgroundColor;
  final Function(String sceneId) onDelete;
  final Function(String sceneId)? onSelect;
  final String? selectedSnapshotId;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String sceneId)? onDragStarted;
  final VoidCallback? onDragEnd;
  final String? draggingSnapshotId;

  const SnapshotList({
    super.key,
    this.backgroundColor,
    required this.snapShotList,
    required this.onDelete,
    this.onSelect,
    this.selectedSnapshotId,
    this.onReorder,
    this.onDragStarted,
    this.onDragEnd,
    this.draggingSnapshotId,
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
            color: Colors.white,
            child: child,
          ),
        );
      },
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapShotList.length,
      onReorder: (int oldIndex, int newIndex) {
        if (onReorder != null) {
          onReorder!(oldIndex, newIndex);
        }
      },
      itemBuilder: (BuildContext context, int index) {
        final SceneModel snapShotData = snapShotList[index];
        final bool isDragging = draggingSnapshotId == snapShotData.id;

        return Container(
          key: ValueKey<String>(snapShotData.id),
          margin: const EdgeInsets.only(bottom: 4),
          child: Draggable<SceneModel>(
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
                width: 200,
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
              ),
            ),
            child: SnapshotItemCard(
              index: index,
              snapShotData: snapShotData,
              isDragging: isDragging,
              isSelected: selectedSnapshotId == snapShotData.id,
              onDelete: () {
                onDelete(snapShotData.id);
              },
              onTap: () {
                if (onSelect != null) {
                  onSelect!(snapShotData.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
