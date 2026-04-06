import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel — Virtual Controller.
///
/// • Title  = selected snapshot-page name OR active scene-set name.
/// • List   = snapshots linked to the selected snapshot-page (snapshotsPerPage),
///            or allSnapshots when a scene-set row is active.
/// • Radio  = tracks activeSnapshotId; tapping updates it.
class SnapshotVcPanel extends StatelessWidget {
  const SnapshotVcPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PanelSectionHeader(title: 'VIRTUAL CONTROLLER'),
              Expanded(child: _buildContent(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ConfigControlLoaded state) {
    // ── Resolve title and snapshot list ─────────────────────────────────────
    String title;
    List<SnapshotsModel> snapshots;

    if (state.selectedSnapshotPageId != null) {
      // A snapshot page row was tapped → show only the snapshots the user
      // selected when creating that page.
      final SnapshotPageModel? page = _findSnapshotPage(state, state.selectedSnapshotPageId!);
      title = page?.name ?? 'Snapshot Page';
      snapshots = _resolveSnapshots(state, page);
    } else if (state.selectedSceneSetId != null) {
      // A scene-set row was tapped in PAGES → show snapshots for that scene set
      final SceneSetModel? sceneSet = _findSceneSet(state, state.selectedSceneSetId!);
      title = sceneSet?.name ?? 'Scene';
      snapshots = state.snapshotsInSceneSets[state.selectedSceneSetId] ?? <SnapshotsModel>[];
    } else {
      title = 'Snapshots';
      snapshots = <SnapshotsModel>[];
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Title ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: FusionAppText(
                  text: title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),

              // ── Snapshot list ─────────────────────────────────────────
              if (snapshots.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: FusionAppText(
                    text:
                        state.selectedSnapshotPageId != null
                            ? 'No snapshots linked to this page'
                            : state.selectedSceneSetId != null
                            ? 'No snapshots in this scene'
                            : 'Select a page or scene to view',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: snapshots.length,
                    itemBuilder: (BuildContext context, int index) {
                      final SnapshotsModel snapshot = snapshots[index];
                      final bool isActive = state.activeSnapshotId == snapshot.id;
                      return _SnapshotRadioItem(
                        snapshot: snapshot,
                        isActive: isActive,
                        onTap: () => context.read<ConfigurationControlViewmodel>().setActiveSnapshot(snapshot.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Finds a SnapshotPageModel by ID from the local snapshotPages list.
  SnapshotPageModel? _findSnapshotPage(ConfigControlLoaded state, String pageId) {
    try {
      return state.snapshotPages.firstWhere((SnapshotPageModel p) => p.id == pageId);
    } catch (_) {
      return null;
    }
  }

  /// Finds a SceneSetModel by ID from the sceneSets list.
  SceneSetModel? _findSceneSet(ConfigControlLoaded state, String sceneSetId) {
    try {
      return state.sceneSets.firstWhere((SceneSetModel s) => s.id == sceneSetId);
    } catch (_) {
      return null;
    }
  }

  /// Resolves the snapshot IDs stored in a SnapshotPageModel to actual
  /// SnapshotsModel instances from state.allSnapshots.
  List<SnapshotsModel> _resolveSnapshots(ConfigControlLoaded state, SnapshotPageModel? page) {
    if (page == null) return <SnapshotsModel>[];
    final Map<String, SnapshotsModel> lookup = <String, SnapshotsModel>{
      for (final SnapshotsModel s in state.allSnapshots) s.id: s,
    };
    return page.snapshotIds.where((String id) => lookup.containsKey(id)).map((String id) => lookup[id]!).toList();
  }
}

// ─── Radio list item ──────────────────────────────────────────────────────────

class _SnapshotRadioItem extends StatelessWidget {
  final SnapshotsModel snapshot;
  final bool isActive;
  final VoidCallback onTap;

  const _SnapshotRadioItem({
    required this.snapshot,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.elevation3 : context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? context.colorScheme.strokeDark : context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FusionAppText(
                    text: snapshot.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FusionAppText(
                    text: 'Label',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textBody,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _RadioIndicator(isActive: isActive),
          ],
        ),
      ),
    );
  }
}

// ─── Radio indicator ──────────────────────────────────────────────────────────

class _RadioIndicator extends StatelessWidget {
  final bool isActive;
  const _RadioIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? context.colorScheme.primaryColor : Colors.transparent,
        border: Border.all(
          color: isActive ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
      ),
      child: isActive ? Icon(Icons.check, size: 13, color: context.colorScheme.primaryWhite) : null,
    );
  }
}
