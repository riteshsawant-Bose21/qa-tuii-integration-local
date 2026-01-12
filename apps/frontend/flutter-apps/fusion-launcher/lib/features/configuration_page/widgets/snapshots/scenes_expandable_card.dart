import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_dialog.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ScenesExpandableCard extends StatefulWidget {
  final SceneSetModel sceneSetData;
  final List<SnapshotsModel> snapShotList;
  final bool isDragHovered;
  final Function(String sceneId) onSceneSetDelete;
  final Function(String sceneSetId)? onSceneSetDuplicate;
  final Function(String snapshotId) onScenesSnapshotDelete;
  final Function(String snapshotId)? onScenesSnapshotDuplicate;
  final Function(String sceneId)? onSelect;
  final Function(String sceneId)? onDragStarted;
  final VoidCallback? onDragEnd;
  final String? draggingSnapshotId;
  final String? draggingFromSection;
  final Function(String sceneSetId, int oldIndex, int newIndex)? onReorderScenes;

  const ScenesExpandableCard({
    this.isDragHovered = false,
    super.key,
    required this.sceneSetData,
    required this.snapShotList,
    required this.onSceneSetDelete,
    this.onSceneSetDuplicate,
    required this.onScenesSnapshotDelete,
    this.onScenesSnapshotDuplicate,
    this.onSelect,
    this.onDragStarted,
    this.onDragEnd,
    this.draggingSnapshotId,
    this.draggingFromSection,
    this.onReorderScenes,
  });

  @override
  State<ScenesExpandableCard> createState() => _ScenesExpandableCardState();
}

class _ScenesExpandableCardState extends State<ScenesExpandableCard> {
  late ValueNotifier<bool> _isScenesExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  final TextEditingController _snapshotsNameController = TextEditingController();

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isScenesExpanded = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _isScenesExpanded.dispose();
    super.dispose();
  }

  void _addNewSceneToSceneSet() {
    final SnapshotsModel newScene = SnapshotsModel(
      name: "New Snapshot ${widget.snapShotList.length + 1}",
    );
    _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: widget.sceneSetData.id, scene: newScene);

    /// expand the scene set to show the new item
    _isScenesExpanded.value = true;

    final SceneActionModel action = SceneActionModel();

    _projectViewModel.addSceneActionToSnapshot(sceneId: newScene.id, action: action);

    /// make this snapshot selected
    _projectViewModel.setSelectedSnapshotId(newScene.id);

    /// Clear dialog and close popup
  }

  /// Clear source set dialog inputs
  void _clearSourceSetDialog({bool pop = false, BuildContext? popContext, bool isScene = false}) {
    _snapshotsNameController.clear();

    if (pop && popContext != null && Navigator.of(popContext).canPop()) {
      Navigator.of(popContext).pop();
    }
    setState(() {});
  }

  /// Add method to expand source set externally
  void expandSourceSet() {
    if (!_isScenesExpanded.value) {
      _isScenesExpanded.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isScenesExpanded,
      builder: (BuildContext context, bool isExpanded, Widget? child) {
        return DragTarget<SnapshotsModel>(
          onWillAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
            /// Accept drops from snapshots section or from other scenes
            return widget.draggingFromSection == 'snapshots' ||
                (widget.draggingFromSection == 'scenes' && !widget.snapShotList.any((SnapshotsModel scene) => scene.id == details.data.id));
          },
          onLeave: (SnapshotsModel? data) {},
          onAcceptWithDetails: (DragTargetDetails<SnapshotsModel> details) {
            if (widget.draggingFromSection == 'snapshots') {
              /// Move from snapshots to this scene set
              /// First check if it's already in this scene set
              final bool alreadyInSet = widget.snapShotList.any((SnapshotsModel scene) => scene.id == details.data.id);

              if (!alreadyInSet) {
                /// Expand the scene set to show the new item
                _isScenesExpanded.value = true;

                // Try using the exact same scene object
                _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: widget.sceneSetData.id, scene: details.data);
              }
            } else if (widget.draggingFromSection == 'scenes') {
              /// Move from another scene set to this one
              final bool alreadyInSet = widget.snapShotList.any((SnapshotsModel scene) => scene.id == details.data.id);

              if (!alreadyInSet) {
                /// Expand the scene set to show the new item
                _isScenesExpanded.value = true;

                /// Add to this scene set first
                _projectViewModel.addNewSnapshotToSceneSet(sceneSetId: widget.sceneSetData.id, scene: details.data);

                /// Remove from all other scene sets
                final List<SceneSetModel> allSceneSets = _projectViewModel.getAllSceneSets();
                for (SceneSetModel sceneSet in allSceneSets) {
                  if (sceneSet.id != widget.sceneSetData.id) {
                    final List<SnapshotsModel> scenesInSet = _projectViewModel.getSnapshotInSceneSet(sceneSetId: sceneSet.id);
                    if (scenesInSet.any((SnapshotsModel scene) => scene.id == details.data.id)) {
                      _projectViewModel.removeSnapshotFromSceneSet(sceneSetId: sceneSet.id, sceneId: details.data.id);
                    }
                  }
                }
              }
            }

            if (widget.onDragEnd != null) {
              widget.onDragEnd!();
            }
          },
          builder: (BuildContext context, List<SnapshotsModel?> candidateData, List<dynamic> rejectedData) {
            final bool isHovered =
                candidateData.isNotEmpty &&
                (widget.draggingFromSection == 'snapshots' ||
                    (widget.draggingFromSection == 'scenes' && !widget.snapShotList.any((SnapshotsModel scene) => scene.id == candidateData.first?.id)));

            return Column(
              children: <Widget>[
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      /// Toggle expand/collapse
                      _isScenesExpanded.value = !_isScenesExpanded.value;
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isHovered ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 1.0,
                        ),
                        color:
                            isHovered
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : (_isHovered ? Theme.of(context).colorScheme.grey.withAlpha(200) : Theme.of(context).colorScheme.greyLight),
                      ),
                      child: Row(
                        children: <Widget>[
                          /// Expand/collapse icon
                          Icon(
                            _isScenesExpanded.value ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                            color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
                          ),
                          const SizedBox(width: 4),

                          /// Source set name
                          Expanded(
                            child: FusionAppText(
                              text: widget.sceneSetData.name,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          /// Add new scene button
                          GestureDetector(
                            onTap: () {
                              _addNewSceneToSceneSet();
                            },
                            child: Icon(Icons.add_sharp, size: 16, color: Theme.of(context).colorScheme.greyDark),
                          ),
                          const SizedBox(width: 8),

                          Tooltip(
                            message: 'Delete Scene Set',
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => FusionDialog(
                                        title: 'Delete Scenes?',
                                        description:
                                            "This will remove '${widget.sceneSetData.name}' from the Scenes. and all its associated snapshots will be deleted.",
                                        primaryButtonLabel: 'Delete',
                                        secondaryButtonLabel: 'Cancel',
                                        onSecondaryPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        onPrimaryPressed: () {
                                          widget.onSceneSetDelete(widget.sceneSetData.id);
                                          Navigator.of(context).pop();
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
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Duplicate Scene Set',
                            child: GestureDetector(
                              onTap: () {
                                if (widget.onSceneSetDuplicate != null) {
                                  widget.onSceneSetDuplicate!(widget.sceneSetData.id);
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
                        ],
                      ),
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    color: isHovered ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.transparent,
                    child:
                        widget.snapShotList.isEmpty
                            ? Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: FusionAppText(
                                text: "No Snapshots Available",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            )
                            : SnapshotList(
                              snapShotList: widget.snapShotList,
                              selectedSnapshotId: _projectViewModel.selectedSnapshotId,
                              onSelect: widget.onSelect,
                              onDelete: (String sceneId) {
                                widget.onScenesSnapshotDelete(sceneId);
                              },
                              onDuplicate: (String sceneId) {
                                if (widget.onScenesSnapshotDuplicate != null) {
                                  widget.onScenesSnapshotDuplicate!(sceneId);
                                }
                              },
                              onReorder: (int oldIndex, int newIndex) {
                                if (widget.onReorderScenes != null) {
                                  widget.onReorderScenes!(widget.sceneSetData.id, oldIndex, newIndex);
                                }
                              },
                              onDragStarted: widget.onDragStarted,
                              onDragEnd: widget.onDragEnd,
                              draggingSnapshotId: widget.draggingSnapshotId,
                            ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
