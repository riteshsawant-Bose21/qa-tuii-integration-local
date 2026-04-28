import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/pages_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/snapshot_and_scenes_section.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/snapshot_vc_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main Snapshots/Scenes panel — three-column layout.
class SnapshotsScenesPanel extends StatelessWidget {
  const SnapshotsScenesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotViewModel, SnapshotState>(
      builder: (BuildContext context, SnapshotState snapState) {
        if (snapState is! SnapshotLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          color: context.colorScheme.elevation1,
          padding: const EdgeInsets.all(16),
          child:  Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Left: SCENES + SNAPSHOT PAGE panel
              const Expanded(flex: 3, child: SnapshotAndScenesSection()),
              const SizedBox(width: 12),

              /// Middle: PAGES panel
              const Expanded(flex: 2, child: PagesPanel()),
              const SizedBox(width: 12),

              /// Right: VIRTUAL CONTROLLER panel
              // const Expanded(flex: 4, child: SnapshotVcPanel()),

              Expanded(flex: 4,
                child: BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
                  builder: (BuildContext context, ConfigurationControlState state) {
                    final WallControllerConfig config = serviceLocator<ProjectViewModel>().getWallControllerConfig();
                    final String prettyJson = const JsonEncoder.withIndent('  ').convert(config.toJson());
                    debugPrint('─── WallControllerConfig JSON when data changes ───');
                    debugPrint(prettyJson);
                    return SnapshotVcPanel(
                      isDesignMode: !serviceLocator<ProjectViewModel>().isInControlMode,
                      controllerID: state.selectedControllerId ?? "",
                      selectedSnapShotId: snapState.selectedSnapshotPageId ?? "",
                      vipAddress: serviceLocator<ProjectViewModel>().virtualIP ?? "192.168.0.100",
                      config: serviceLocator<ProjectViewModel>().getWallControllerConfig(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
