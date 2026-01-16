import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/scenes_expandable_card.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../drag_divider.dart';

class SnapshotsAndScenesPanel extends StatefulWidget {
  const SnapshotsAndScenesPanel({super.key});

  @override
  State<SnapshotsAndScenesPanel> createState() => _SnapshotsAndScenesPanelState();
}

class _SnapshotsAndScenesPanelState extends State<SnapshotsAndScenesPanel> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  late double _sourcesHeight;
  final TextEditingController _snapshotsNameController = TextEditingController();
  final TextEditingController _scenesNameController = TextEditingController();

  // Add dragging state management
  String? _draggingSnapshotId;
  String? _draggingFromSection; // 'snapshots' or 'scenes'

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = screenHeight * 0.15; // 15% of screen height as minimum
    final double maxHeight = screenHeight * 0.5; // 50% of screen height as maximum

    setState(() {
      _sourcesHeight = (_sourcesHeight + delta).clamp(minHeight, maxHeight);
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    final double totalHeight = MediaQuery.of(context).size.height;
    _sourcesHeight = (totalHeight - 100) * 0.4; // 40% of available height after accounting for headers
  }

  /// Add new snapshots
  void _addNewSnapshots() {
    final SnapshotsModel newScene = SnapshotsModel(
      name: "New Snapshot ${_projectViewModel.getAllSnapshots().length + 1}",
    );
    _projectViewModel.addNewSnapshots(scene: newScene);

    /// select the newly added snapshot
    _projectViewModel.setSelectedSnapshotId(newScene.id);

    /// Also add a default action to the new snapshot
    final SceneActionModel action = SceneActionModel();

    _projectViewModel.addSceneActionToSnapshot(sceneId: newScene.id, action: action);

    FusionToast.success(context, message: "Snapshot \"${newScene.name}\" created");
  }

  /// Add new scenes
  void _addNewScenes() {
    final SceneSetModel newSceneSet = SceneSetModel(
      name: "New Scene Set ${_projectViewModel.getAllSceneSets().length + 1}",
    );
    _projectViewModel.addNewSceneSet(sceneSet: newSceneSet);
    FusionToast.success(context, message: 'Scene "${newSceneSet.name}" created');
  }

  /// Handle reordering of snapshots
  void _handleSnapshotReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    _projectViewModel.reOderSnapshots(sceneIdToMove: newIndex.toString(), sceneIdAtNewIndex: oldIndex.toString());
  }

  /// Handle reordering of scenes within a scene set
  void _handleSceneSetReorder(String sceneSetId, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    _projectViewModel.reOrderSnapshotInSceneSet(
      sceneSetId: sceneSetId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryWhite,
      ),
      child: Column(
        children: <Widget>[
          /// Snapshots Section
          SectionHeader(
            title: 'Snapshots',
            trailing: GestureDetector(
              onTap: () {
                _addNewSnapshots();
              },
              child: Icon(
                Icons.add_sharp,
                size: 16,
                color: context.colorScheme.primaryBlack,
              ),
            ),
          ),

          /// list of snapshots would go here, constrained to _sourcesHeight SnapshotItemCard
          /// Sources list with controlled height
          DragTarget<SnapshotsModel>(
            onWillAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
              // Only accept if dragging from scenes section, not from snapshots section
              return _draggingFromSection == 'scenes';
            },
            onLeave: (SnapshotsModel? data) {},
            onAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
              if (_draggingFromSection == 'scenes') {
                /// First check if it already exists in snapshots to avoid duplicates
                final List<SnapshotsModel> existing = _projectViewModel.getAllSnapshots();
                final bool alreadyInList = existing.any((SnapshotsModel s) => s.id == details.data.id);

                if (!alreadyInList) {
                  /// Add to snapshots section first
                  _projectViewModel.addNewSnapshots(scene: details.data);
                }

                /// Remove from all scene sets (since it's now in snapshots)
                final List<SceneSetModel> allSceneSets = _projectViewModel.getAllSceneSets();
                for (SceneSetModel sceneSet in allSceneSets) {
                  final List<SnapshotsModel> scenesInSet = _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSet.id);
                  if (scenesInSet.any((SnapshotsModel scene) => scene.id == details.data.id)) {
                    _projectViewModel.removeSnapshotFromSceneSet(sceneSetId: sceneSet.id, sceneId: details.data.id);
                  }
                }
              }
              setState(() {
                _draggingSnapshotId = null;
                _draggingFromSection = null;
              });
            },
            builder: (BuildContext context, List<SnapshotsModel?> candidateData, List<dynamic> rejectedData) {
              final bool isHovered = candidateData.isNotEmpty && _draggingFromSection == 'scenes';
              return Container(
                decoration: BoxDecoration(
                  color: isHovered ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                  border:
                      isHovered
                          ? Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          )
                          : null,
                ),
                height: _sourcesHeight,
                child: SingleChildScrollView(
                  child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                    builder: (BuildContext context, ProjectViewModelState state) {
                      final List<SnapshotsModel> snapShotList = _projectViewModel.getAllSnapshots();
                      if (snapShotList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(top: _sourcesHeight * 0.4),
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
                          _projectViewModel.removeSnapshots(sceneId: sceneId);

                          /// clear on selected snapshot to avoid confusion after delete
                          _projectViewModel.setSelectedSnapshotId(null);
                          FusionToast.success(context, message: "Snapshot deleted successfully");
                        },
                        selectedSnapshotId: _projectViewModel.selectedSnapshotId,
                        onSelect: (String sceneId) {
                          _projectViewModel.setSelectedSnapshotId(sceneId);
                        },
                        onDuplicate: (String sceneId) {
                          _projectViewModel.duplicateSnapshot(sceneId: sceneId);
                          FusionToast.success(context, message: "Snapshot duplicated successfully");
                        },
                        onReorder: _handleSnapshotReorder,
                        onDragStarted: (String sceneId) {
                          setState(() {
                            _draggingSnapshotId = sceneId;
                            _draggingFromSection = 'snapshots';
                          });
                        },
                        onDragEnd: () {
                          setState(() {
                            _draggingSnapshotId = null;
                            _draggingFromSection = null;
                          });
                        },
                        draggingSnapshotId: _draggingSnapshotId,
                        onRenameSave: (String value, SnapshotsModel newSnapshot) {
                          _projectViewModel.updateSnapshots(scene: newSnapshot);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),

          /// Draggable divider
          DragDivider(onDragUpdate: _updateSourcesHeight),

          /// Scenes Section
          SectionHeader(
            title: 'Scene Sets',
            trailing: GestureDetector(
              onTap: () {
                _addNewScenes();
              },
              child: Icon(Icons.add_sharp, size: 16, color: context.colorScheme.primaryBlack),
            ),
          ),

          /// List of Scenes
          Expanded(
            child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
              builder: (BuildContext context, ProjectViewModelState state) {
                final List<SceneSetModel> scenesSetList = _projectViewModel.getAllSceneSets();
                if (scenesSetList.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: _sourcesHeight * 0.4),
                    child: FusionAppText(
                      text: 'No scenes available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: scenesSetList.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 8);
                  },
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final SceneSetModel sceneSetData = scenesSetList[index];
                    final List<SnapshotsModel> associatedScenes = _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSetData.id);
                    return ScenesExpandableCard(
                      sceneSetData: sceneSetData,
                      isDragHovered: false,
                      snapShotList: associatedScenes,
                      onSelect: (String sceneId) {
                        _projectViewModel.setSelectedSnapshotId(sceneId);
                      },
                      onSceneSetDelete: (String sceneSetId) {
                        _projectViewModel.removeSceneSet(sceneSetId: sceneSetId);

                        /// clear selected snapshot to avoid confusion after delete
                        _projectViewModel.setSelectedSnapshotId(null);
                        FusionToast.success(context, message: "Scenes deleted successfully");
                      },
                      onSceneSetDuplicate: (String sceneSetId) {
                        _projectViewModel.duplicateSceneSet(sceneSetId: sceneSetId);
                        FusionToast.success(context, message: "Scene Set duplicated successfully");
                      },
                      onScenesSnapshotDelete: (String sceneId) {
                        _projectViewModel.removeSnapshots(sceneId: sceneId);

                        /// clear selected snapshot to avoid confusion after delete
                        _projectViewModel.setSelectedSnapshotId(null);
                        FusionToast.success(context, message: "Snapshot deleted successfully");
                      },
                      onScenesSnapshotDuplicate: (String sceneId) {
                        _projectViewModel.duplicateSnapshot(sceneId: sceneId);
                        FusionToast.success(context, message: "Snapshot duplicated successfully");
                      },
                      onReorderScenes: _handleSceneSetReorder,
                      onDragStarted: (String sceneId) {
                        setState(() {
                          _draggingSnapshotId = sceneId;
                          _draggingFromSection = 'scenes';
                        });
                      },
                      onDragEnd: () {
                        setState(() {
                          _draggingSnapshotId = null;
                          _draggingFromSection = null;
                        });
                      },
                      draggingSnapshotId: _draggingSnapshotId,
                      draggingFromSection: _draggingFromSection,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
