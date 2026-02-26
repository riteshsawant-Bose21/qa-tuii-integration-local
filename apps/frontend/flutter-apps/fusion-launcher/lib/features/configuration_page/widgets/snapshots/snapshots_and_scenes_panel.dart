import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/scene_sets_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/scene_sets_state.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshots_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshots_state.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/scenes_expandable_card.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../drag_divider.dart';

class SnapshotsAndScenesPanel extends StatefulWidget {
  const SnapshotsAndScenesPanel({super.key});

  @override
  State<SnapshotsAndScenesPanel> createState() => _SnapshotsAndScenesPanelState();
}

class _SnapshotsAndScenesPanelState extends State<SnapshotsAndScenesPanel> {
  bool _isInitialized = false;

  SnapshotsCubit get _snapshotsCubit => context.read<SnapshotsCubit>();
  SceneSetsCubit get _sceneSetsCubit => context.read<SceneSetsCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final double screenHeight = MediaQuery.of(context).size.height;
      _snapshotsCubit.initializeSourcesHeight(screenHeight);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    _snapshotsCubit.updateSourcesHeight(delta, screenHeight);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotsCubit, SnapshotsState>(
      builder: (BuildContext context, SnapshotsState snapshotsState) {
        return BlocBuilder<SceneSetsCubit, SceneSetsState>(
          builder: (BuildContext context, SceneSetsState sceneSetsState) {
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
                        _snapshotsCubit.addSnapshot();
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
                      return _snapshotsCubit.shouldAcceptDropOnSnapshots();
                    },
                    onLeave: (SnapshotsModel? data) {},
                    onAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
                      _snapshotsCubit.handleDropOnSnapshots(details.data);
                      _sceneSetsCubit.syncWithProjectViewModel();
                    },
                    builder: (BuildContext context, List<SnapshotsModel?> candidateData, List<dynamic> rejectedData) {
                      final bool isHovered = candidateData.isNotEmpty && snapshotsState.isDraggingFromScenes;
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
                        height: snapshotsState.sourcesHeight,
                        child: SingleChildScrollView(
                          child: _buildSnapshotsList(context, snapshotsState),
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
                        _sceneSetsCubit.addSceneSet();
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
                      child: _buildSceneSetsList(context, snapshotsState, sceneSetsState),
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

  Widget _buildSnapshotsList(BuildContext context, SnapshotsState state) {
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
        _snapshotsCubit.deleteSnapshot(sceneId);
        FusionToast.success(context, message: "Snapshot deleted successfully");
      },
      selectedSnapshotId: state.selectedSnapshotId,
      onSelect: (String sceneId) {
        _snapshotsCubit.selectSnapshot(sceneId);
      },
      onDuplicate: (String sceneId) {
        _snapshotsCubit.duplicateSnapshot(sceneId);
        FusionToast.success(context, message: "Snapshot duplicated successfully");
      },
      onReorder: (int oldIndex, int newIndex) {
        _snapshotsCubit.reorderSnapshots(oldIndex, newIndex);
      },
      onDragStarted: (String sceneId) {
        _snapshotsCubit.startDrag(sceneId, DragSection.snapshots);
      },
      onDragEnd: () {
        _snapshotsCubit.endDrag();
      },
      draggingSnapshotId: state.draggingSnapshotId,
      onRenameSave: (String value, SnapshotsModel newSnapshot) {
        _snapshotsCubit.updateSnapshot(newSnapshot);
      },
    );
  }

  Widget _buildSceneSetsList(BuildContext context, SnapshotsState snapshotsState, SceneSetsState sceneSetsState) {
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
        final List<SnapshotsModel> associatedScenes = _sceneSetsCubit.getSnapshotsInSceneSet(sceneSetData.id);
        return ScenesExpandableCard(
          sceneSetData: sceneSetData,
          isDragHovered: false,
          snapShotList: associatedScenes,
          onSelect: (String sceneId) {
            _snapshotsCubit.selectSnapshot(sceneId);
          },
          onSceneSetDelete: (String sceneSetId) {
            _sceneSetsCubit.deleteSceneSet(sceneSetId);
            FusionToast.success(context, message: "Scenes deleted successfully");
          },
          onSceneSetDuplicate: (String sceneSetId) {
            _sceneSetsCubit.duplicateSceneSet(sceneSetId);
            FusionToast.success(context, message: "Scene Set duplicated successfully");
          },
          onScenesSnapshotDelete: (String sceneId) {
            _snapshotsCubit.deleteSnapshot(sceneId);
            _sceneSetsCubit.syncWithProjectViewModel();
            FusionToast.success(context, message: "Snapshot deleted successfully");
          },
          onScenesSnapshotDuplicate: (String sceneId) {
            _snapshotsCubit.duplicateSnapshot(sceneId);
            _sceneSetsCubit.syncWithProjectViewModel();
            FusionToast.success(context, message: "Snapshot duplicated successfully");
          },
          onReorderScenes: (String sceneSetId, int oldIndex, int newIndex) {
            _sceneSetsCubit.reorderSnapshotsInSceneSet(
              sceneSetId: sceneSetId,
              oldIndex: oldIndex,
              newIndex: newIndex,
              draggingSnapshotId: snapshotsState.draggingSnapshotId,
            );
          },
          onDragStarted: (String sceneId) {
            _snapshotsCubit.startDrag(sceneId, DragSection.scenes);
          },
          onDragEnd: () {
            _snapshotsCubit.endDrag();
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
