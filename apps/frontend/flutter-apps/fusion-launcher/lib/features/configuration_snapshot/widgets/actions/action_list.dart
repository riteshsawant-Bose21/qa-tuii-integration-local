import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/actions_viewmodel/config_snapshot_actions_state.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/actions_viewmodel/config_snapshot_actions_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/actions/snapshot_action_row_data.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/actions/snapshot_action_row_header.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/actions/snapshot_header_widget.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/snapshots/SnapshotsKeys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_set_model.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

class ActionList extends StatelessWidget {
  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.actionlistpanel),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: context.colorScheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: context.colorScheme.elevation2),
        ),
        child: Column(
          children: <Widget>[
            /// Action List
            BlocBuilder<ConfigSnapshotActionsViewModel, ConfigSnapshotActionsState>(
              builder: (BuildContext context, ConfigSnapshotActionsState state) {
                return switch (state) {
                  SnapshotActionsInitial() => _buildNoSnapshotSelected(context),
                  SnapshotActionsLoading() => _buildLoading(context),
                  SnapshotActionsLoaded() => _buildLoaded(context, state),
                  SnapshotActionsError() => _buildError(context, state),
                };
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build widget when no snapshot is selected
  Widget _buildNoSnapshotSelected(BuildContext context) {
    return Expanded(
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.actionlistpanelemty),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FusionAppText(
                  semanticId: FusionTestKeys.instance.actionlistpanelemtylabel,
                  text: 'Select a Snapshot to view and manage its actions',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                FusionAppText(
                  semanticId: FusionTestKeys.instance.actionlistpanelemtydesc1,
                  text:
                      "Snapshots are predefined configurations that allow you to switch between different audio setups quickly. Each snapshot can contain multiple actions that define how audio sources are routed and managed within the system.",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FusionAppText(
                  semanticId: FusionTestKeys.instance.actionlistpanelemtydesc2,
                  text:
                      "To get started, select a snapshot from the list on the left. Once selected, you can add, edit, or remove actions associated with that snapshot using the controls provided in this panel.",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build loading widget
  Widget _buildLoading(BuildContext context) {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Build error widget
  Widget _buildError(BuildContext context, SnapshotActionsError state) {
    return Expanded(
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.actionlistpanelerror),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FusionIcon.icon(semanticId: 'action_list_error_icon', Icons.error_outline, size: 48, color: context.colorScheme.error),
              const SizedBox(height: 16),
              FusionAppText(
                semanticId: FusionTestKeys.instance.actionlistpanelerrorlabel,
                text: 'Error loading actions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              FusionAppText(
                semanticId: FusionTestKeys.instance.actionlistpanelerrormessage,
                text: state.message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build loaded widget with actions list
  Widget _buildLoaded(BuildContext context, SnapshotActionsLoaded state) {
    final ConfigSnapshotActionsViewModel actionsCubit = context.read<ConfigSnapshotActionsViewModel>();
    final ConfigSnapshotsViewmodel configSnapshotsViewmodel = context.read<ConfigSnapshotsViewmodel>();

    final List<SceneActionModel> actionsList = state.actions;
    final SnapshotsModel? selectedScene = configSnapshotsViewmodel.getSelectedSnapshotModel();
    final SceneSetModel? sceneSet = configSnapshotsViewmodel.getSceneSetForSelectedSnapshot();

    return Expanded(
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.actionlistpaneldata),
        child: Column(
          children: <Widget>[
            /// Snapshot Header Widget
            SnapshotHeaderWidget(
              snapshotName: sceneSet != null ? "${sceneSet.name} > ${selectedScene?.name}" : selectedScene?.name ?? "",
              onNameChanged: (String newName) {
                if (selectedScene != null) {
                  final SnapshotsModel scene = selectedScene.copyWith(name: newName);
                  configSnapshotsViewmodel.updateSnapshot(scene);
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
                      ? SemanticHelper.container(
                        testId: FusionTestKeys.instance.actionlistpanelrowdataemty,
                        child: Center(
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
                        ),
                      )
                      : SemanticHelper.container(
                        testId: FusionTestKeys.instance.actionlistpanelrowdata,
                        child: ReorderableListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}
