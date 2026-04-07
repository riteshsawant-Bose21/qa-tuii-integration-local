import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/create_snapshot_page_form.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SnapshotPageSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const SnapshotPageSection({super.key, required this.state});

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
                child: FusionIcon.icon(
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
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(text: page.name, style: Theme.of(context).textTheme.l1Regular),
          ),
          FusionKebabPopup(
            onDelete: onDelete,
          ),
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
