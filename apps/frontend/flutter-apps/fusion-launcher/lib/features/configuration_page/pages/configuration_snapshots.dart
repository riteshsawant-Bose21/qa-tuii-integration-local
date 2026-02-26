import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/scene_sets_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshot_actions_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshots_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshots_state.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshots_and_scenes_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/snapshots/action_list.dart';

class ConfigurationSnapshots extends StatelessWidget {
  const ConfigurationSnapshots({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<SnapshotsCubit>(
          create:
              (BuildContext context) => SnapshotsCubit(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<SceneSetsCubit>(
          create:
              (BuildContext context) => SceneSetsCubit(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<SnapshotActionsCubit>(
          create:
              (BuildContext context) => SnapshotActionsCubit(
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
    return BlocListener<SnapshotsCubit, SnapshotsState>(
      listenWhen: (SnapshotsState previous, SnapshotsState current) => previous.selectedSnapshotId != current.selectedSnapshotId,
      listener: (BuildContext context, SnapshotsState state) {
        // When selected snapshot changes, load actions for the new snapshot
        context.read<SnapshotActionsCubit>().loadActionsForSnapshot(state.selectedSnapshotId);
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
