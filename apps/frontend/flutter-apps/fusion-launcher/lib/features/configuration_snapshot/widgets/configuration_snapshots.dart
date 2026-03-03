import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/snapshots_and_scenes_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../viewModel/actions_viewmodel/config_snapshot_actions_viewmodel.dart';
import '../viewModel/scenes_viewmodel/config_scene_sets_viewmodel.dart';
import '../viewModel/snapshot_viewmodel/config_snapshots_state.dart';
import 'actions/action_list.dart';

class ConfigurationSnapshots extends StatelessWidget {
  const ConfigurationSnapshots({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ConfigSnapshotsViewmodel>(
          create:
              (BuildContext context) => ConfigSnapshotsViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<ConfigSceneSetsViewmodel>(
          create:
              (BuildContext context) => ConfigSceneSetsViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<ConfigSnapshotActionsViewModel>(
          create:
              (BuildContext context) => ConfigSnapshotActionsViewModel(
                projectViewModel: projectViewModel,
              ),
        ),
      ],
      child: const _ConfigurationSnapshotsBody(),
    );
  }
}

class _ConfigurationSnapshotsBody extends StatefulWidget {
  const _ConfigurationSnapshotsBody();

  @override
  State<_ConfigurationSnapshotsBody> createState() => _ConfigurationSnapshotsBodyState();
}

class _ConfigurationSnapshotsBodyState extends State<_ConfigurationSnapshotsBody> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigSnapshotsViewmodel, ConfigSnapshotsState>(
      listenWhen: (ConfigSnapshotsState previous, ConfigSnapshotsState current) => previous.selectedSnapshotId != current.selectedSnapshotId,
      listener: (BuildContext context, ConfigSnapshotsState state) {
        // When selected snapshot changes, load actions for the new snapshot
        context.read<ConfigSnapshotActionsViewModel>().loadActionsForSnapshot(state.selectedSnapshotId);
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Row(
                children: <Widget>[
                  SizedBox(width: constraints.maxWidth * 0.3, child: const SnapshotsAndScenesPanel()),
                  const SizedBox(width: 4),
                  const Expanded(child: ActionList()),
                ],
              );
            } else {
              return const Column(
                children: <Widget>[
                  Expanded(flex: 1, child: SnapshotsAndScenesPanel()),
                  Expanded(flex: 2, child: ActionList()),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
