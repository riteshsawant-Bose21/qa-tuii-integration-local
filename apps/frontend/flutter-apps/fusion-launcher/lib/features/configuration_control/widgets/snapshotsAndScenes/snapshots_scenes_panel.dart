import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      builder: (BuildContext context, SnapshotState state) {
        if (state is! SnapshotLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          color: context.colorScheme.elevation1,
          padding: const EdgeInsets.all(16),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Left: SCENES + SNAPSHOT PAGE panel
              Expanded(flex: 3, child: SnapshotAndScenesSection()),
              SizedBox(width: 12),

              /// Middle: PAGES panel
              Expanded(flex: 2, child: PagesPanel()),
              SizedBox(width: 12),

              /// Right: VIRTUAL CONTROLLER panel
              Expanded(flex: 4, child: SnapshotVcPanel()),
            ],
          ),
        );
      },
    );
  }
}
