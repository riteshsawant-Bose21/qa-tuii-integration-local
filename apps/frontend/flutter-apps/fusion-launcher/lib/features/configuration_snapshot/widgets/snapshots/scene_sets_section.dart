import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';
import '../../../configuration_page/widgets/section_header.dart';
import '../../viewModel/scenes_viewmodel/config_scene_sets_state.dart';
import '../../viewModel/scenes_viewmodel/config_scene_sets_viewmodel.dart';
import '../../viewModel/snapshot_viewmodel/config_snapshots_state.dart';
import '../../viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';
import '../scenes_sets/scenes_expandable_card.dart';

class SceneSets extends StatefulWidget {
  const SceneSets({super.key});

  @override
  State<SceneSets> createState() => _SceneSetsState();
}

class _SceneSetsState extends State<SceneSets> {
  ConfigSceneSetsViewmodel get _configSceneSetsViewmodel => context.read<ConfigSceneSetsViewmodel>();

  ConfigSnapshotsViewmodel get _configSnapshotsViewmodel => context.read<ConfigSnapshotsViewmodel>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigSnapshotsViewmodel, ConfigSnapshotsState>(
      builder: (
        BuildContext context,
        ConfigSnapshotsState configSnapshotsState,
      ) {
        return BlocBuilder<ConfigSceneSetsViewmodel, ConfigSceneSetsState>(
          builder: (
            BuildContext context,
            ConfigSceneSetsState configSceneSetsState,
          ) {
            return Column(
              children: <Widget>[
                SectionHeader(
                  semanticLabel: 'scenes',
                  title: 'Scene Sets',
                  isRounded: false,
                  trailing: GestureDetector(
                    onTap: () {
                      _configSceneSetsViewmodel.addSceneSet();
                      FusionToast.success(
                        context,
                        message: 'Scene Set created',
                      );
                    },
                    child: Icon(
                      Icons.add_sharp,
                      size: 16,
                      color: context.colorScheme.primaryWhite,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation1,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: context.colorScheme.elevation2,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildSceneSetsList(
                      context,
                      configSnapshotsState,
                      configSceneSetsState,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSceneSetsList(
    BuildContext context,
    ConfigSnapshotsState snapshotsState,
    ConfigSceneSetsState sceneSetsState,
  ) {
    final List<SceneSetModel> scenesSetList = sceneSetsState.sceneSets;
    if (scenesSetList.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: FusionAppText(
          text: 'No scenes available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: scenesSetList.length,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        final SceneSetModel sceneSetData = scenesSetList[index];
        final List<SnapshotsModel> associatedScenes = sceneSetsState.snapshotsInSceneSets[sceneSetData.id] ?? <SnapshotsModel>[];
        return ScenesExpandableCard(
          sceneSetData: sceneSetData,
          isDragHovered: false,
          snapShotList: associatedScenes,
          onSelect: (String sceneId) {
            _configSnapshotsViewmodel.selectSnapshot(sceneId);
          },
          onSceneSetDelete: (String sceneSetId) {
            _configSceneSetsViewmodel.deleteSceneSet(sceneSetId);
            FusionToast.success(
              context,
              message: "Scenes deleted successfully",
            );
          },
          onSceneSetDuplicate: (String sceneSetId) {
            _configSceneSetsViewmodel.duplicateSceneSet(sceneSetId);
            FusionToast.success(
              context,
              message: "Scene Set duplicated successfully",
            );
          },
          onScenesSnapshotDelete: (String sceneId) {
            _configSnapshotsViewmodel.deleteSnapshot(sceneId);
            _configSceneSetsViewmodel.syncWithProjectViewModel();
            FusionToast.success(
              context,
              message: "Snapshot deleted successfully",
            );
          },
          onScenesSnapshotDuplicate: (String sceneId) {
            _configSnapshotsViewmodel.duplicateSnapshot(sceneId);
            _configSceneSetsViewmodel.syncWithProjectViewModel();
            FusionToast.success(
              context,
              message: "Snapshot duplicated successfully",
            );
          },
          onReorderScenes: (String sceneSetId, int oldIndex, int newIndex) {
            _configSceneSetsViewmodel.reorderSnapshotsInSceneSet(
              sceneSetId: sceneSetId,
              oldIndex: oldIndex,
              newIndex: newIndex,
              draggingSnapshotId: snapshotsState.draggingSnapshotId,
            );
          },
          onDragStarted: (String sceneId) {
            _configSnapshotsViewmodel.startDrag(sceneId, DragSection.scenes);
          },
          onDragEnd: () {
            _configSnapshotsViewmodel.endDrag();
          },
          draggingSnapshotId: snapshotsState.draggingSnapshotId,
          draggingFromSection:
              snapshotsState.draggingFromSection == DragSection.snapshots
                  ? 'snapshots'
                  : snapshotsState.draggingFromSection == DragSection.scenes
                  ? 'scenes'
                  : null,
        );
      },
    );
  }
}
