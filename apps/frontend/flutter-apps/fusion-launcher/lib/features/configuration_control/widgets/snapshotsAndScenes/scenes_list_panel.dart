import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/create_snapshot_page_form.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Left column: SCENES checkboxes (top) + SNAPSHOT PAGE management (bottom).
///
/// These two sections are INDEPENDENT:
/// • Checkbox (selectedSceneSetIds)  → controls which sets appear in PAGES panel.
/// • Row tap  (selectedSceneSetId)   → controls which set's pages appear in
///   SNAPSHOT PAGE section and Virtual Controller.
class ScenesListPanel extends StatelessWidget {
  const ScenesListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        return Column(
          children: <Widget>[
            Expanded(child: _ScenesSection(state: state)),
            const SizedBox(height: 12),
            Expanded(child: _SnapshotPageSection(state: state)),
          ],
        );
      },
    );
  }
}

// ─── SCENES section ───────────────────────────────────────────────────────────

class _ScenesSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const _ScenesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PanelSectionHeader(title: 'SCENES'),
          Expanded(
            child:
                state.sceneSets.isEmpty
                    ? Center(
                      child: FusionAppText(
                        text: 'No scenes available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.sceneSets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final SceneSetModel sceneSet = state.sceneSets[index];
                        final bool isChecked = state.selectedSceneSetIds.contains(sceneSet.id);
                        return _SceneSetItem(
                          sceneSet: sceneSet,
                          isChecked: isChecked,
                          // Checkbox tap → toggles PAGES-panel membership only
                          onToggle: () => context.read<ConfigurationControlViewmodel>().toggleSceneSetSelection(sceneSet.id),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _SceneSetItem extends StatelessWidget {
  final SceneSetModel sceneSet;
  final bool isChecked;
  final VoidCallback onToggle;

  const _SceneSetItem({
    required this.sceneSet,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FusionCheckbox(isChecked: isChecked),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: sceneSet.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isChecked ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SNAPSHOT PAGE section ────────────────────────────────────────────────────
// Independent of scene checkboxes — shows pages for the ACTIVE scene set
// (set by tapping a scene row, not by toggling a checkbox).

class _SnapshotPageSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const _SnapshotPageSection({required this.state});

  Future<void> _openCreateForm(BuildContext context, ConfigControlLoaded state) async {
    // Collect all snapshot IDs already assigned to existing snapshot pages
    final Set<String> usedIds = state.snapshotPages.expand((SnapshotPageModel p) => p.snapshotIds).toSet();

    // Only offer snapshots not yet assigned to any snapshot page
    final List<SnapshotsModel> availableSnapshots = state.allSnapshots.where((SnapshotsModel s) => !usedIds.contains(s.id)).toList();

    final CreateSnapshotPageResult? result = await showCreateSnapshotPageDialog(
      context: context,
      availableSnapshots: availableSnapshots,
    );
    if (result == null || !context.mounted) return;
    context.read<ConfigurationControlViewmodel>().createSnapshotPage(
      name: result.name,
      selectedSnapshotIds: result.selectedIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show user-created snapshot pages, not individual snapshots.
    final List<SnapshotPageModel> pages = state.snapshotPages;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PanelSectionHeader(
            title: 'SNAPSHOT PAGE',
            trailing: GestureDetector(
              onTap: () => _openCreateForm(context, state),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                pages.isEmpty
                    ? Center(
                      child: FusionAppText(
                        text: 'Tap + to add pages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: pages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final SnapshotPageModel page = pages[index];
                        return _SnapshotPageItem(
                          page: page,
                          onDelete: () => context.read<ConfigurationControlViewmodel>().deleteSnapshotPage(page.id),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotPageItem extends StatelessWidget {
  final SnapshotPageModel page;
  final VoidCallback onDelete;

  const _SnapshotPageItem({
    required this.page,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: page.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          _PageContextMenu(page: page, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _PageContextMenu extends StatelessWidget {
  final SnapshotPageModel page;
  final VoidCallback onDelete;

  const _PageContextMenu({required this.page, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: context.colorScheme.iconDefault),
      color: context.colorScheme.elevation2,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 140),
      itemBuilder:
          (_) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: <Widget>[
                  Icon(Icons.delete_outline, size: 16, color: context.colorScheme.errorText),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: context.colorScheme.errorText, fontSize: 13)),
                ],
              ),
            ),
          ],
      onSelected: (String value) {
        if (value == 'delete') onDelete();
      },
    );
  }
}

// ─── Shared checkbox widget ───────────────────────────────────────────────────

class _FusionCheckbox extends StatelessWidget {
  final bool isChecked;
  const _FusionCheckbox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isChecked ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
        color: isChecked ? context.colorScheme.primaryColor : Colors.transparent,
      ),
      child: isChecked ? Icon(Icons.check, size: 11, color: context.colorScheme.primaryWhite) : null,
    );
  }
}
