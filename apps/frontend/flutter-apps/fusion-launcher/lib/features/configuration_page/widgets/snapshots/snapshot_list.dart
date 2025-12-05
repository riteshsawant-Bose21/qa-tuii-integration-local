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
///  );
/// ```
///
/// Parameters:
/// - [snapShotList]: A required list of [SceneModel] objects to be displayed.
/// - [backgroundColor]: An optional color for the background of the list.
/// /// Returns:
/// A [Container] widget containing a [ReorderableListView] of snapshot items.

class SnapshotList extends StatelessWidget {
  final List<SceneModel> snapShotList;
  final Color? backgroundColor;
  final Function(String sceneId) onDelete;
  final Function(String sceneId)? onSelect;
  final String? selectedSnapshotId;
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
    this.onDragStarted,
    this.onDragEnd,
    this.draggingSnapshotId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapShotList.length,
      separatorBuilder:
          (BuildContext context, int index) => const SizedBox(
            height: 8,
          ),
      itemBuilder: (BuildContext context, int index) {
        final SceneModel snapShotData = snapShotList[index];
        final bool isDragging = draggingSnapshotId == snapShotData.id;

        return Draggable<SceneModel>(
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
        );
      },
    );
  }
}
