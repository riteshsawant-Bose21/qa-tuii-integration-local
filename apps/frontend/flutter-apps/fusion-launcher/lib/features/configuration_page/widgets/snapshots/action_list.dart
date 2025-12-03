import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_data.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_header_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../search_bar_sources.dart';

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
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,

                  // width 30% of the parent width
                  width: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
                    ),
                  ),
                  child: SearchBarSources(
                    searchController: TextEditingController(),
                    isFromActionList: true,
                    hasActiveFilters: () => false,
                    onClearSearch: () {},
                    onSearchChanged: (String value) {},
                  ),
                ),
              ],
            ),
          ),

          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final String? selectedSnapshotId = _projectViewModel.selectedSnapshotId;
              if (selectedSnapshotId == null) {
                return const SizedBox.shrink();
              }
              return Column(
                children: <Widget>[
                  /// Snapshot Header Widget
                  SnapshotHeaderWidget(
                    onAdd: () {
                      final SceneActionModel action = SceneActionModel();
                      _projectViewModel.addSceneActionToScene(sceneId: selectedSnapshotId, action: action);
                    },
                    onReorder: () {},
                  ),

                  /// Action Row Header
                  const SnapshotActionRowHeader(),

                  /// show list of actions for the selected scene/snapshots
                  Column(
                    children:
                        _projectViewModel
                            .getSceneActionsForScene(selectedSnapshotId)
                            .map(
                              (SceneActionModel action) => SnapshotActionRowData(
                                action: action,
                              ),
                            )
                            .toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
