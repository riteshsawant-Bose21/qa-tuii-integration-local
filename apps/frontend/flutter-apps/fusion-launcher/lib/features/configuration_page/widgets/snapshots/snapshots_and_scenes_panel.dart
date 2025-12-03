import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/scenes_expandable_card.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';

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
  void _addNewSnapshots(BuildContext popupContext) {
    final SceneModel newScene = SceneModel(
      name: _snapshotsNameController.text.trim(),
    );
    _projectViewModel.addNewScene(scene: newScene);

    /// Clear dialog and close popup
    _clearSourceSetDialog(pop: true, popContext: popupContext);
  }

  /// Add new scenes
  void _addNewScenes(BuildContext popupContext) {
    final SceneSetModel newSceneSet = SceneSetModel(
      name: _scenesNameController.text.trim(),
    );
    _projectViewModel.addNewSceneSet(sceneSet: newSceneSet);

    /// Clear dialog and close popup
    _clearSourceSetDialog(pop: true, popContext: popupContext, isScene: true);
  }

  /// Clear source set dialog inputs
  void _clearSourceSetDialog({bool pop = false, BuildContext? popContext, bool isScene = false}) {
    if (isScene) {
      _scenesNameController.clear();
    } else {
      _snapshotsNameController.clear();
    }

    if (pop && popContext != null && Navigator.of(popContext).canPop()) {
      Navigator.of(popContext).pop();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
      ),
      child: Column(
        children: <Widget>[
          /// Snapshots Section
          SectionHeader(
            title: 'Snapshots',
            trailing: PopupMenuButton<dynamic>(
              onCanceled: () {
                // _clearSourceSetDialog();
                // setState(() {});
              },
              tooltip: "Add Snapshot Set",
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
                                _addNewSnapshots(context);
                              },
                              onCancel: () {
                                /// Cancel inside popup: close only popup.
                                // _clearSourceSetDialog(pop: true, popContext: context);
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
          ),

          /// list of snapshots would go here, constrained to _sourcesHeight SnapshotItemCard
          SizedBox(
            height: _sourcesHeight,
            child: SingleChildScrollView(
              child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  final List<SceneModel> snapShotList = _projectViewModel.getAllScenes();
                  if (snapShotList.isEmpty) {
                    return Padding(
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
                      _projectViewModel.removeScene(sceneId: sceneId);
                    },
                    onSelect: (String sceneId) {
                      _projectViewModel.setSelectedSnapshotId(sceneId);
                    },
                  );
                },
              ),
            ),
          ),

          /// Draggable divider
          DragDivider(onDragUpdate: _updateSourcesHeight),

          /// Scenes Section
          SectionHeader(
            title: 'Scenes',
            trailing: PopupMenuButton<dynamic>(
              onCanceled: () {},
              tooltip: "Add Scenes",
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
                              headerText: 'Scenes',
                              nameController: _scenesNameController,
                              onCreate: () {
                                /// Add new scenes
                                /// Clear dialog and close popup
                                _addNewScenes(context);
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
              child: IconButton(
                icon: Icon(Icons.add_sharp, size: 16, color: Theme.of(context).colorScheme.greyDark),
                onPressed: null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
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
                    final List<SceneModel> associatedScenes = _projectViewModel.getScenesInSceneSet(sceneSetId: sceneSetData.id);
                    return ScenesExpandableCard(
                      sceneSetData: sceneSetData,
                      isDragHovered: false,
                      snapShotList: associatedScenes,
                      onSceneSetDelete: (String sceneSetId) {
                        _projectViewModel.removeSceneSet(sceneSetId: sceneSetId);
                      },
                      onScenesSnapshotDelete: (String sceneId) {
                        _projectViewModel.removeScene(sceneId: sceneId);
                      },
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
      color: Theme.of(context).colorScheme.white,
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
          //
          // /// Source Selection Label
          // FusionAppText(
          //   text: 'Select sources',
          //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //     fontSize: 12,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          // const SizedBox(height: 8),
          //
          // /// Source Selection Dropdown
          // Container(
          //   height: 28,
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey[300]!),
          //     borderRadius: BorderRadius.circular(4),
          //   ),
          //   child: PopupMenuButton<String>(
          //     onCanceled: () {
          //       // Handle popup close if needed
          //     },
          //     constraints: const BoxConstraints(
          //       maxHeight: 500,
          //       maxWidth: 240,
          //     ),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     color: Theme.of(context).colorScheme.white,
          //     offset: const Offset(0, 35),
          //     itemBuilder: (BuildContext context) {
          //       return <PopupMenuEntry<String>>[
          //         PopupMenuItem<String>(
          //           enabled: false,
          //           padding: EdgeInsets.zero,
          //           child: StatefulBuilder(
          //             builder: (BuildContext context, StateSetter setPopupState) {
          //               return Container(
          //                 width: 240,
          //                 constraints: const BoxConstraints(maxHeight: 460),
          //                 child: Column(
          //                   mainAxisSize: MainAxisSize.min,
          //                   children: <Widget>[
          //                     /// Header with close button
          //                     Container(
          //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //                       decoration: BoxDecoration(
          //                         border: Border(
          //                           bottom: BorderSide(color: Colors.grey[300]!),
          //                         ),
          //                       ),
          //                       child: Row(
          //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                         children: <Widget>[
          //                           FusionAppText(
          //                             text: "Select source",
          //                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                               fontSize: 12,
          //                               fontWeight: FontWeight.w600,
          //                             ),
          //                           ),
          //                           InkWell(
          //                             onTap: () {
          //                               Navigator.of(context).pop();
          //                             },
          //                             child: Icon(
          //                               Icons.close,
          //                               size: 16,
          //                               color: Theme.of(context).colorScheme.fusionTextViewColor,
          //                             ),
          //                           ),
          //                         ],
          //                       ),
          //                     ),
          //
          //                     /// Scrollable list of sources
          //                     Flexible(
          //                       child:
          //                           widget.availableSources.isNotEmpty
          //                               ? SingleChildScrollView(
          //                                 physics: const ClampingScrollPhysics(),
          //                                 child: Column(
          //                                   children:
          //                                       widget.availableSources.map<Widget>((Source source) {
          //                                         final bool isSelected = widget.selectedSources.any(
          //                                           (SelectedSource selectedSource) => selectedSource.id == source.id,
          //                                         );
          //                                         return InkWell(
          //                                           onTap: () {
          //                                             widget.onSourceChanged(source, !isSelected);
          //                                             setPopupState(() {});
          //                                             setState(() {});
          //                                           },
          //                                           child: Container(
          //                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          //                                             color: Colors.transparent,
          //                                             child: Row(
          //                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                                               children: <Widget>[
          //                                                 /// Checkbox for selection
          //                                                 SizedBox(
          //                                                   width: 14,
          //                                                   height: 14,
          //                                                   child: Checkbox(
          //                                                     value: isSelected,
          //                                                     onChanged: (bool? value) {
          //                                                       widget.onSourceChanged(source, value ?? false);
          //                                                       setPopupState(() {}); // Update popup state
          //                                                       setState(() {}); // Update main widget state
          //                                                     },
          //                                                     activeColor: Theme.of(context).colorScheme.greyDark,
          //                                                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //                                                     visualDensity: VisualDensity.compact,
          //                                                     shape: const RoundedRectangleBorder(
          //                                                       borderRadius: BorderRadius.zero,
          //                                                       side: BorderSide(width: 0.5),
          //                                                     ),
          //                                                   ),
          //                                                 ),
          //                                                 const SizedBox(width: 12),
          //
          //                                                 /// Source name
          //                                                 Expanded(
          //                                                   child: FusionAppText(
          //                                                     text: source.name,
          //                                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                                                       fontWeight: FontWeight.w500,
          //                                                       fontSize: 10,
          //                                                       color: Theme.of(context).textTheme.bodySmall?.color,
          //                                                     ),
          //                                                   ),
          //                                                 ),
          //                                               ],
          //                                             ),
          //                                           ),
          //                                         );
          //                                       }).toList(),
          //                                 ),
          //                               )
          //                               : Padding(
          //                                 padding: const EdgeInsets.all(12.0),
          //                                 child: FusionAppText(
          //                                   text: "No Source Available",
          //                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                                     fontSize: 10,
          //                                   ),
          //                                 ),
          //                               ),
          //                     ),
          //                   ],
          //                 ),
          //               );
          //             },
          //           ),
          //         ),
          //       ];
          //     },
          //     child: Container(
          //       height: 29,
          //       padding: const EdgeInsets.symmetric(horizontal: 8),
          //       child: Row(
          //         children: <Widget>[
          //           Expanded(
          //             child: FusionAppText(
          //               text:
          //                   widget.selectedSources.isEmpty
          //                       ? "Select Sources"
          //                       : "${widget.selectedSources.length} source${widget.selectedSources.length > 1 ? 's' : ''} selected",
          //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                 color: widget.selectedSources.isEmpty ? Theme.of(context).colorScheme.greyDark : Theme.of(context).textTheme.bodySmall?.color,
          //               ),
          //             ),
          //           ),
          //           Icon(
          //             Icons.keyboard_arrow_down,
          //             size: 20,
          //             color: Theme.of(context).colorScheme.greyDark,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          //
          // const SizedBox(height: 12),
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
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                  label: "Create",
                  // isActive: widget.nameController.text.trim().isNotEmpty && widget.selectedSources.length >= 2,
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
