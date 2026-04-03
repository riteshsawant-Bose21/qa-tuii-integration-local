import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Middle panel — PAGES:
///
/// • Checked scene sets → appear as page rows (row tap drives SNAPSHOT PAGE + VC).
/// • Snapshot pages from the active scene set → ALWAYS shown regardless of checkbox state.
/// • One item can be active at a time:
///     - Scene-set row active only when selectedSnapshotPageId == null.
///     - Snapshot-page row active when selectedSnapshotPageId matches.
/// • Newly created snapshot page is auto-selected (via selectedSnapshotPageId in state).
class PagesPanel extends StatelessWidget {
  const PagesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        // Checked scene sets (only these appear as scene-set rows)
        final List<SceneSetModel> selectedSets = state.sceneSets.where((SceneSetModel s) => state.selectedSceneSetIds.contains(s.id)).toList();

        // Snapshot pages from the ACTIVE scene set — always shown
        final List<SnapshotsModel> activePages =
            state.selectedSceneSetId != null ? (state.snapshotsInSceneSets[state.selectedSceneSetId] ?? <SnapshotsModel>[]) : <SnapshotsModel>[];

        final bool nothingToShow = selectedSets.isEmpty && activePages.isEmpty;

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PanelSectionHeader(title: 'PAGES'),
              Expanded(
                child:
                    nothingToShow
                        ? Center(
                          child: FusionAppText(
                            text: 'No pages available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),
                        )
                        : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children: <Widget>[
                            // ── Checked scene-set rows ───────────────────────────
                            ...selectedSets.map((SceneSetModel s) {
                              // Scene-set row is active only when NO snapshot page is selected
                              final bool isActive = s.id == state.selectedSceneSetId && state.selectedSnapshotPageId == null;
                              return _PageRow(
                                label: s.name,
                                isActive: isActive,
                                onTap: () => context.read<ConfigurationControlViewmodel>().selectSceneSet(s.id),
                              );
                            }),

                            // ── Snapshot pages — ALWAYS visible ──────────────────
                            ...activePages.map((SnapshotsModel page) {
                              final bool isActive = state.selectedSnapshotPageId == page.id;
                              return _PageRow(
                                label: page.name,
                                isActive: isActive,
                                onTap: () => context.read<ConfigurationControlViewmodel>().selectSnapshotPage(page.id),
                              );
                            }),
                          ],
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single page row ──────────────────────────────────────────────────────────
// Identical visual for scene-set and snapshot-page rows:
//   Active   → primaryColor solid fill + white text/icon.
//   Inactive → elevation2 bg + strokeLight border.

class _PageRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PageRow({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.primaryColor : context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? context.colorScheme.primaryColor : context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.drag_indicator,
              size: 14,
              color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault,
            ),
            const SizedBox(width: 2),
            Text(
              ':',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FusionAppText(
                text: label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
