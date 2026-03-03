import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/scenes_sets/scenes_expandable_card.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/widgets/configuration_widgets/drag_divider.dart';
import '../../viewModel/scenes_viewmodel/config_scene_sets_state.dart';
import '../../viewModel/scenes_viewmodel/config_scene_sets_viewmodel.dart';
import '../../viewModel/snapshot_viewmodel/config_snapshots_state.dart';

class SnapshotsAndScenesPanel extends StatefulWidget {
  const SnapshotsAndScenesPanel({super.key});

  @override
  State<SnapshotsAndScenesPanel> createState() => _SnapshotsAndScenesPanelState();
}

class _SnapshotsAndScenesPanelState extends State<SnapshotsAndScenesPanel> {
  bool _isInitialized = false;

  ConfigSnapshotsViewmodel get _configSnapshotsViewmodel => context.read<ConfigSnapshotsViewmodel>();
  ConfigSceneSetsViewmodel get _configSceneSetsViewmodel => context.read<ConfigSceneSetsViewmodel>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final double screenHeight = MediaQuery.of(context).size.height;
      _configSnapshotsViewmodel.initializeSourcesHeight(screenHeight);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    _configSnapshotsViewmodel.updateSourcesHeight(delta, screenHeight);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigSnapshotsViewmodel, ConfigSnapshotsState>(
      builder: (BuildContext context, ConfigSnapshotsState configSnapshotsState) {
        return BlocBuilder<ConfigSceneSetsViewmodel, ConfigSceneSetsState>(
          builder: (BuildContext context, ConfigSceneSetsState configSceneSetsState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryBlack,
              ),
              child: Column(
                children: <Widget>[
                  /// Snapshots Section
                  SectionHeader(
                    title: 'Snapshots',
                    trailing: GestureDetector(
                      onTap: () {
                        _configSnapshotsViewmodel.addSnapshot();
                        FusionToast.success(context, message: "Snapshot created");
                      },
                      child: Icon(
                        Icons.add_sharp,
                        size: 16,
                        color: context.colorScheme.iconWhite,
                      ),
                    ),
                  ),

                  /// Snapshots list with drag target
                  DragTarget<SnapshotsModel>(
                    onWillAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
                      return _configSnapshotsViewmodel.shouldAcceptDropOnSnapshots();
                    },
                    onLeave: (SnapshotsModel? data) {},
                    onAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
                      _configSnapshotsViewmodel.handleDropOnSnapshots(details.data);
                      _configSceneSetsViewmodel.syncWithProjectViewModel();
                    },
                    builder: (BuildContext context, List<SnapshotsModel?> candidateData, List<dynamic> rejectedData) {
                      final bool isHovered = candidateData.isNotEmpty && configSnapshotsState.isDraggingFromScenes;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isHovered ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : context.colorScheme.elevation1,
                          border:
                              isHovered
                                  ? Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    width: 2,
                                  )
                                  : Border.symmetric(
                                    vertical: BorderSide(color: context.colorScheme.elevation2, width: 1),
                                  ),
                        ),
                        height: configSnapshotsState.sourcesHeight,
                        child: SingleChildScrollView(
                          child: _buildSnapshotsList(context, configSnapshotsState),
                        ),
                      );
                    },
                  ),

                  /// Draggable divider
                  DragDivider(onDragUpdate: _updateSourcesHeight),

                  /// Scenes Section
                  SectionHeader(
                    title: 'Scene Sets',
                    isRounded: false,
                    trailing: GestureDetector(
                      onTap: () {
                        _configSceneSetsViewmodel.addSceneSet();
                        FusionToast.success(context, message: 'Scene Set created');
                      },
                      child: Icon(Icons.add_sharp, size: 16, color: context.colorScheme.primaryWhite),
                    ),
                  ),

                  /// List of Scenes
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation1,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: Border.symmetric(
                          vertical: BorderSide(color: context.colorScheme.elevation2, width: 1),
                        ),
                      ),
                      child: _buildSceneSetsList(context, configSnapshotsState, configSceneSetsState),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSnapshotsList(BuildContext context, ConfigSnapshotsState state) {
    final List<SnapshotsModel> snapShotList = state.snapshots;
    if (snapShotList.isEmpty) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: state.sourcesHeight * 0.4),
        child: FusionAppText(
          text: 'No snapshots available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
          ),
        ),
      );
    }
    return SnapshotList(
      snapShotList: snapShotList,
      onDelete: (String sceneId) {
        _configSnapshotsViewmodel.deleteSnapshot(sceneId);
        FusionToast.success(context, message: "Snapshot deleted successfully");
      },
      selectedSnapshotId: state.selectedSnapshotId,
      onSelect: (String sceneId) {
        _configSnapshotsViewmodel.selectSnapshot(sceneId);
      },
      onDuplicate: (String sceneId) {
        _configSnapshotsViewmodel.duplicateSnapshot(sceneId);
        FusionToast.success(context, message: "Snapshot duplicated successfully");
      },
      onReorder: (int oldIndex, int newIndex) {
        _configSnapshotsViewmodel.reorderSnapshots(oldIndex, newIndex);
      },
      onDragStarted: (String sceneId) {
        _configSnapshotsViewmodel.startDrag(sceneId, DragSection.snapshots);
      },
      onDragEnd: () {
        _configSnapshotsViewmodel.endDrag();
      },
      draggingSnapshotId: state.draggingSnapshotId,
      onRenameSave: (String value, SnapshotsModel newSnapshot) {
        _configSnapshotsViewmodel.updateSnapshot(newSnapshot);
      },
    );
  }

  Widget _buildSceneSetsList(BuildContext context, ConfigSnapshotsState ConfigSnapshotsState, ConfigSceneSetsState configSceneSetsState) {
    final List<SceneSetModel> scenesSetList = configSceneSetsState.sceneSets;
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
        final List<SnapshotsModel> associatedScenes = configSceneSetsState.snapshotsInSceneSets[sceneSetData.id] ?? <SnapshotsModel>[];
        return ScenesExpandableCard(
          sceneSetData: sceneSetData,
          isDragHovered: false,
          snapShotList: associatedScenes,
          onSelect: (String sceneId) {
            _configSnapshotsViewmodel.selectSnapshot(sceneId);
          },
          onSceneSetDelete: (String sceneSetId) {
            _configSceneSetsViewmodel.deleteSceneSet(sceneSetId);
            FusionToast.success(context, message: "Scenes deleted successfully");
          },
          onSceneSetDuplicate: (String sceneSetId) {
            _configSceneSetsViewmodel.duplicateSceneSet(sceneSetId);
            FusionToast.success(context, message: "Scene Set duplicated successfully");
          },
          onScenesSnapshotDelete: (String sceneId) {
            _configSnapshotsViewmodel.deleteSnapshot(sceneId);
            _configSceneSetsViewmodel.syncWithProjectViewModel();
            FusionToast.success(context, message: "Snapshot deleted successfully");
          },
          onScenesSnapshotDuplicate: (String sceneId) {
            _configSnapshotsViewmodel.duplicateSnapshot(sceneId);
            _configSceneSetsViewmodel.syncWithProjectViewModel();
            FusionToast.success(context, message: "Snapshot duplicated successfully");
          },
          onReorderScenes: (String sceneSetId, int oldIndex, int newIndex) {
            _configSceneSetsViewmodel.reorderSnapshotsInSceneSet(
              sceneSetId: sceneSetId,
              oldIndex: oldIndex,
              newIndex: newIndex,
              draggingSnapshotId: ConfigSnapshotsState.draggingSnapshotId,
            );
          },
          onDragStarted: (String sceneId) {
            _configSnapshotsViewmodel.startDrag(sceneId, DragSection.scenes);
          },
          onDragEnd: () {
            _configSnapshotsViewmodel.endDrag();
          },
          draggingSnapshotId: ConfigSnapshotsState.draggingSnapshotId,
          draggingFromSection:
              ConfigSnapshotsState.draggingFromSection == DragSection.snapshots
                  ? 'snapshots'
                  : ConfigSnapshotsState.draggingFromSection == DragSection.scenes
                  ? 'scenes'
                  : null,
        );
      },
    );
  }
}

/// Widget for creating a new Snapshot or Scene
class CreateSnapshotsOrScenesWidget extends StatefulWidget {
  final String headerText;
  final TextEditingController nameController;

  final VoidCallback onCreate;
  final VoidCallback onCancel;

  const CreateSnapshotsOrScenesWidget({
    super.key,
    required this.nameController,

    required this.onCreate,
    required this.onCancel,
    required this.headerText,
  });

  @override
  State<CreateSnapshotsOrScenesWidget> createState() => CreateSnapshotsOrScenesWidgetState();
}

class CreateSnapshotsOrScenesWidgetState extends State<CreateSnapshotsOrScenesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryWhite,
      width: 250,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Create ${widget.headerText}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          FusionAppText(
            text: "${widget.headerText} Name",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          /// Enter Name
          FusionTextField(
            controller: widget.nameController,
            hintText: "Enter ${widget.headerText} name",
            decoration: FusionInputDecoration.fusionDense(
              colorScheme: Theme.of(context).colorScheme,
              hintText: 'Enter ${widget.headerText} name',
            ),
            onChanged: (String value) {
              setState(() {});
            },
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: FusionOutlinedButton(
                  width: double.infinity,
                  label: "Cancel",
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                  onTap: () {
                    widget.onCancel.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FusionButton(
                  width: double.infinity,
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: context.colorScheme.primaryBlack),

                  label: "Create",
                  isActive: widget.nameController.text.trim().isNotEmpty,
                  onTap: () {
                    widget.onCreate.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
