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

  const SnapshotList({
    super.key,
    this.backgroundColor,
    required this.snapShotList,
    required this.onDelete,
    this.onSelect,
    this.selectedSnapshotId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapShotList.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(),
      itemBuilder: (BuildContext context, int index) {
        final SceneModel snapShotData = snapShotList[index];
        return SnapshotItemCard(
          snapShotData: snapShotData,
          isDragging: false,
          isSelected: selectedSnapshotId == snapShotData.id,
          onDelete: () {
            onDelete(snapShotData.id);
          },
          onTap: () {
            if (onSelect != null) {
              onSelect!(snapShotData.id);
            }
          },
        );
      },
    );
  }
}
