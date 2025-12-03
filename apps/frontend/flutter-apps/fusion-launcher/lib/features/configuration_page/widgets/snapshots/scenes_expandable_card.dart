import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshots_and_scenes_panel.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ScenesExpandableCard extends StatefulWidget {
  final SceneSetModel sceneSetData;
  final List<SceneModel> snapShotList;
  final bool isDragHovered;
  final Function(String sceneId) onSceneSetDelete;
  final Function(String snapshotId) onScenesSnapshotDelete;
  final Function(String sceneId)? onDragStarted;
  final VoidCallback? onDragEnd;
  final String? draggingSnapshotId;
  final String? draggingFromSection;

  const ScenesExpandableCard({
    this.isDragHovered = false,
    super.key,
    required this.sceneSetData,
    required this.snapShotList,
    required this.onSceneSetDelete,
    required this.onScenesSnapshotDelete,
    this.onDragStarted,
    this.onDragEnd,
    this.draggingSnapshotId,
    this.draggingFromSection,
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
    _isScenesExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isScenesExpanded.dispose();
    super.dispose();
  }

  void _addNewSceneToSceneSet(BuildContext popupContext) {
    final SceneModel newScene = SceneModel(
      name: _snapshotsNameController.text.trim(),
    );
    _projectViewModel.addNewSceneToSceneSet(sceneSetId: widget.sceneSetData.id, scene: newScene);

    /// Clear dialog and close popup
    _clearSourceSetDialog(pop: true, popContext: popupContext);
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
        return DragTarget<SceneModel>(
          onWillAcceptWithDetails: (DragTargetDetails<SceneModel> details) {
            /// Accept drops from snapshots section or from other scenes
            return widget.draggingFromSection == 'snapshots' ||
                (widget.draggingFromSection == 'scenes' && !widget.snapShotList.any((SceneModel scene) => scene.id == details.data.id));
          },
          onLeave: (SceneModel? data) {},
          onAcceptWithDetails: (DragTargetDetails<SceneModel> details) {
            if (widget.draggingFromSection == 'snapshots') {
              /// Move from snapshots to this scene set
              /// First check if it's already in this scene set
              final bool alreadyInSet = widget.snapShotList.any((SceneModel scene) => scene.id == details.data.id);

              if (!alreadyInSet) {
                /// Expand the scene set to show the new item
                _isScenesExpanded.value = true;

                // Try using the exact same scene object
                _projectViewModel.addNewSceneToSceneSet(sceneSetId: widget.sceneSetData.id, scene: details.data);
              }
            } else if (widget.draggingFromSection == 'scenes') {
              /// Move from another scene set to this one
              final bool alreadyInSet = widget.snapShotList.any((SceneModel scene) => scene.id == details.data.id);

              if (!alreadyInSet) {
                /// Expand the scene set to show the new item
                _isScenesExpanded.value = true;

                /// Add to this scene set first
                _projectViewModel.addNewSceneToSceneSet(sceneSetId: widget.sceneSetData.id, scene: details.data);

                /// Remove from all other scene sets
                final List<SceneSetModel> allSceneSets = _projectViewModel.getAllSceneSets();
                for (SceneSetModel sceneSet in allSceneSets) {
                  if (sceneSet.id != widget.sceneSetData.id) {
                    final List<SceneModel> scenesInSet = _projectViewModel.getScenesInSceneSet(sceneSetId: sceneSet.id);
                    if (scenesInSet.any((SceneModel scene) => scene.id == details.data.id)) {
                      _projectViewModel.removeSceneFromSceneSet(sceneSetId: sceneSet.id, sceneId: details.data.id);
                    }
                  }
                }
              }
            }

            if (widget.onDragEnd != null) {
              widget.onDragEnd!();
            }
          },
          builder: (BuildContext context, List<SceneModel?> candidateData, List<dynamic> rejectedData) {
            final bool isHovered =
                candidateData.isNotEmpty &&
                (widget.draggingFromSection == 'snapshots' ||
                    (widget.draggingFromSection == 'scenes' && !widget.snapShotList.any((SceneModel scene) => scene.id == candidateData.first?.id)));

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
                          PopupMenuButton<dynamic>(
                            onCanceled: () {
                              _clearSourceSetDialog();
                            },
                            tooltip: "Add Snapshot",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              maxHeight: 500,
                              maxWidth: 250,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Theme.of(context).colorScheme.white,
                            menuPadding: EdgeInsets.zero,

                            itemBuilder: (BuildContext context) {
                              return <PopupMenuItem<dynamic>>[
                                PopupMenuItem<dynamic>(
                                  enabled: false,
                                  padding: EdgeInsets.zero,
                                  child: SizedBox(
                                    width: 250,
                                    child: StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setMenuState) {
                                        return SingleChildScrollView(
                                          child: CreateSnapshotsOrScenesWidget(
                                            headerText: 'Snapshot',
                                            nameController: _snapshotsNameController,
                                            onCreate: () {
                                              /// Pass popup context so only the menu closes.
                                              _addNewSceneToSceneSet(context);
                                            },
                                            onCancel: () {
                                              /// Cancel inside popup: close only popup.
                                              _clearSourceSetDialog(pop: true, popContext: context);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ];
                            },
                            child: Icon(Icons.add_sharp, size: 16, color: Theme.of(context).colorScheme.greyDark),
                          ),
                          const SizedBox(width: 8),

                          Tooltip(
                            message: 'Delete Scenes',
                            child: GestureDetector(
                              onTap: _confirmDeleteScenes,
                              child: const FusionImage.asset(
                                Assets.deleteIcon,
                                width: 17,
                                height: 17,
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
                        onDelete: (String sceneId) {
                          widget.onScenesSnapshotDelete(sceneId);
                        },
                        onDragStarted: widget.onDragStarted,
                        onDragEnd: widget.onDragEnd,
                        draggingSnapshotId: widget.draggingSnapshotId,
                      ),
              ],
            );
          },
        );
      },
    );
  }

  /// Confirm delete scenes dialog
  Future<void> _confirmDeleteScenes() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        final ColorScheme scheme = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: scheme.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 50),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: "Delete Scenes?",
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FusionAppText(
                    text: "This will remove '${widget.sceneSetData.name}' from the Scenes.",
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 90,
                        child: FusionOutlinedButton(
                          label: "Cancel",
                          textStyle: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontSize: 11),
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: FusionButton(
                          label: "Delete",
                          textStyle: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            color: scheme.fusionButtonTextColor,
                          ),
                          isActive: true,
                          onTap: () {
                            widget.onSceneSetDelete(widget.sceneSetData.id);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
