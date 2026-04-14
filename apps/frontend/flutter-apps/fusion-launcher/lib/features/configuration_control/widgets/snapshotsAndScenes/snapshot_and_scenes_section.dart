import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/scenes_section.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/snapshot_page_section.dart';

/// Left column: SCENES checkboxes (top) + SNAPSHOT PAGE management (bottom).
///
/// These two sections are INDEPENDENT:
/// • Checkbox (selectedSceneSetIds)  → controls which sets appear in PAGES panel.
/// • Row tap  (selectedSceneSetId)   → controls which set's pages appear in
///   SNAPSHOT PAGE section and Virtual Controller.
class SnapshotAndScenesSection extends StatelessWidget {
  const SnapshotAndScenesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotViewModel, SnapshotState>(
      builder: (BuildContext context, SnapshotState state) {
        if (state is! SnapshotLoaded) return const SizedBox.shrink();

        return Column(
          children: <Widget>[
            Expanded(child: ScenesSection(state: state)),
            const SizedBox(height: 12),
            Expanded(child: SnapshotPageSection(state: state)),
          ],
        );
      },
    );
  }
}
