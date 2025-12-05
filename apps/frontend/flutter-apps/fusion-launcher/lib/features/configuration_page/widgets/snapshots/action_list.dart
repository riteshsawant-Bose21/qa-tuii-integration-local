import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_data.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_header_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ActionList extends StatelessWidget {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,

        border: Border(
          left: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Header with Search Bar
          // Container(
          //   height: 44,
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     border: Border(
          //       bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
          //     ),
          //   ),
          //   child: Row(
          //     children: <Widget>[
          //       Container(
          //         alignment: Alignment.center,
          //
          //         // width 30% of the parent width
          //         width: MediaQuery.of(context).size.width * 0.2,
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           border: Border(
          //             right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
          //           ),
          //         ),
          //         child: SearchBarSources(
          //           searchController: TextEditingController(),
          //           isFromActionList: true,
          //           hasActiveFilters: () => false,
          //           onClearSearch: () {},
          //           onSearchChanged: (String value) {},
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          /// Action List
          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final String? selectedSnapshotId = _projectViewModel.selectedSnapshotId;
              if (selectedSnapshotId == null) {
                /// No snapshot selected
                return Expanded(
                  child: Center(
                    child: Container(
                      // 40%
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.all(100.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(
                            text: 'Select a Snapshot to view and manage its actions',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FusionAppText(
                            text:
                                "Snapshots are predefined configurations that allow you to switch between different audio setups quickly. Each snapshot can contain multiple actions that define how audio sources are routed and managed within the system.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.greyDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FusionAppText(
                            text:
                                "To get started, select a snapshot from the list on the left. Once selected, you can add, edit, or remove actions associated with that snapshot using the controls provided in this panel.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.greyDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final List<SceneActionModel> actionsList = _projectViewModel.getSceneActionsForScene(selectedSnapshotId);

              /// get selected snapshot name
              final SceneModel? selectedScene = _projectViewModel.getSceneById(sceneId: selectedSnapshotId);
              return Expanded(
                child: Column(
                  children: <Widget>[
                    /// Snapshot Header Widget
                    SnapshotHeaderWidget(
                      snapshotName: selectedScene?.name ?? "",
                      onAdd: () {
                        final SceneActionModel action = SceneActionModel();

                        _projectViewModel.addSceneActionToScene(sceneId: selectedSnapshotId, action: action);
                      },
                      onReorder: () {},
                    ),

                    /// Action Row Header
                    const SnapshotActionRowHeader(),

                    /// show list of actions for the selected scene/snapshots
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children:
                              actionsList
                                  .map(
                                    (SceneActionModel action) => SnapshotActionRowData(
                                      action: action,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
