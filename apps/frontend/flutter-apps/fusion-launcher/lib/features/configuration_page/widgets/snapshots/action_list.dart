import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshot_actions_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshot_actions_state.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshots_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_data.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_action_row_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_header_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

class ActionList extends StatelessWidget {
  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: context.colorScheme.elevation2),
      ),
      child: Column(
        children: <Widget>[
          /// Action List
          BlocBuilder<SnapshotActionsCubit, SnapshotActionsState>(
            builder: (BuildContext context, SnapshotActionsState actionsState) {
              final SnapshotActionsCubit actionsCubit = context.read<SnapshotActionsCubit>();
              final SnapshotsCubit snapshotsCubit = context.read<SnapshotsCubit>();
              final String? selectedSnapshotId = actionsState.selectedSnapshotId;

              if (selectedSnapshotId == null) {
                /// No snapshot selected
                return Expanded(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.all(100.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(text: 'Select a Snapshot to view and manage its actions', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          FusionAppText(
                            text:
                                "Snapshots are predefined configurations that allow you to switch between different audio setups quickly. Each snapshot can contain multiple actions that define how audio sources are routed and managed within the system.",
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FusionAppText(
                            text:
                                "To get started, select a snapshot from the list on the left. Once selected, you can add, edit, or remove actions associated with that snapshot using the controls provided in this panel.",
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final List<SceneActionModel> actionsList = actionsState.actions;
              final SnapshotsModel? selectedScene = snapshotsCubit.getSelectedSnapshotModel();
              final SceneSetModel? sceneSet = snapshotsCubit.getSceneSetForSelectedSnapshot();

              return Expanded(
                child: Column(
                  children: <Widget>[
                    /// Snapshot Header Widget
                    SnapshotHeaderWidget(
                      snapshotName: sceneSet != null ? "${sceneSet.name} > ${selectedScene?.name}" : selectedScene?.name ?? "",
                      onNameChanged: (String newName) {
                        if (selectedScene != null) {
                          final SnapshotsModel scene = selectedScene.copyWith(name: newName);
                          snapshotsCubit.updateSnapshot(scene);
                        }
                      },
                      onAdd: () {
                        actionsCubit.addAction();
                      },
                      onReorder: () {},
                    ),

                    /// Action Row Header
                    const SnapshotActionRowHeader(),

                    /// show list of actions for the selected scene/snapshots
                    Expanded(
                      child:
                          actionsList.isEmpty
                              ? Center(
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  padding: const EdgeInsets.all(100.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: "No actions added to this snapshot yet.",
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              : ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                physics: const ClampingScrollPhysics(),
                                itemCount: actionsList.length,
                                onReorder: (int oldIndex, int newIndex) {
                                  actionsCubit.reorderActions(oldIndex, newIndex);
                                },
                                itemBuilder: (BuildContext context, int index) {
                                  final SceneActionModel action = actionsList[index];
                                  return SnapshotActionRowData(
                                    key: ValueKey<String>(action.id),
                                    action: action,
                                    index: index,
                                  );
                                },
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
