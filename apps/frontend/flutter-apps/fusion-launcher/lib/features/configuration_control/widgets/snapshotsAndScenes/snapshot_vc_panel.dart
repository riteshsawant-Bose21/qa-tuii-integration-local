import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel — Virtual Controller (snapshot/scene tab).
class SnapshotVcPanel extends StatelessWidget {
  const SnapshotVcPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotViewModel, SnapshotState>(
      builder: (BuildContext context, SnapshotState state) {
        if (state is! SnapshotLoaded) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PanelSectionHeader(semanticId: FusionTestKeys.instance.snapshotAndScenesTabVirtualControllerHeader, title: 'VIRTUAL CONTROLLER'),
              Expanded(child: _buildContent(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SnapshotLoaded state) {
    String title;
    List<SnapshotsModel> snapshots;

    if (state.selectedSnapshotPageId != null) {
      final SnapshotPageModel? page = _findSnapshotPage(state, state.selectedSnapshotPageId!);
      title = page?.name ?? 'Snapshot Page';
      snapshots = _resolveSnapshots(state, page);
    } else if (state.selectedSceneSetId != null) {
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
            color:  context.colorScheme.primaryBlack,
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
                Container(
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
                  child: SnapshotsScreen(snapshots: snapshots),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SnapshotPageModel? _findSnapshotPage(SnapshotLoaded state, String pageId) {
    try {
      return state.snapshotPages.firstWhere((SnapshotPageModel p) => p.id == pageId);
    } catch (_) {
      return null;
    }
  }

  SceneSetModel? _findSceneSet(SnapshotLoaded state, String sceneSetId) {
    try {
      return state.sceneSets.firstWhere((SceneSetModel s) => s.id == sceneSetId);
    } catch (_) {
      return null;
    }
  }

  List<SnapshotsModel> _resolveSnapshots(SnapshotLoaded state, SnapshotPageModel? page) {
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
