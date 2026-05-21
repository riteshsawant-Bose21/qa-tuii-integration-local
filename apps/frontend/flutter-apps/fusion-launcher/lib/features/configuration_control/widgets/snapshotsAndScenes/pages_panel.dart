import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Middle panel — PAGES (snapshot/scene tab).
class PagesPanel extends StatelessWidget {
  const PagesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotViewModel, SnapshotState>(
      builder: (BuildContext context, SnapshotState state) {
        if (state is! SnapshotLoaded) return const SizedBox.shrink();

        // Ordered page entries — preserves insertion order
        final List<ControllerPageModel> orderedEntries = state.orderedPageEntries;

        final bool nothingToShow = orderedEntries.isEmpty;

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PanelSectionHeader(semanticId: FusionTestKeys.instance.snapshotAndScenesPagesSectionHeader, title: 'PAGES'),
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
                        : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          buildDefaultDragHandles: false,
                          onReorder: (int oldIndex, int newIndex) {
                            context.read<SnapshotViewModel>().reorderPages(oldIndex, newIndex);
                          },
                          proxyDecorator: (Widget child, int index, Animation<double> animation) {
                            return Material(
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          itemCount: orderedEntries.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ControllerPageModel entry = orderedEntries[index];
                            if (entry.type == ControllerPageType.sceneSet) {
                              final bool isActive = entry.id == state.selectedSceneSetId && state.selectedSnapshotPageId == null;
                              return _PageRow(
                                key: ValueKey<String>(entry.id),
                                index: index,
                                label: entry.name,
                                isActive: isActive,
                                onTap: () => context.read<SnapshotViewModel>().selectSceneSet(entry.id),
                              );
                            } else {
                              final bool isActive = state.selectedSnapshotPageId == entry.id;
                              return _PageRow(
                                key: ValueKey<String>(entry.id),
                                index: index,
                                label: entry.name,
                                isActive: isActive,
                                onTap: () => context.read<SnapshotViewModel>().selectSnapshotPage(entry.id),
                              );
                            }
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

// ─── Single page row ──────────────────────────────────────────────────────────
// Identical visual for scene-set and snapshot-page rows:
//   Active   → primaryColor solid fill + white text/icon.
//   Inactive → elevation2 bg + strokeLight border.

class _PageRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int index;

  const _PageRow({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.index,
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
            ReorderableDragStartListener(
              index: index,
              child: FusionIcon.svg(
                semanticId: 'snapshot_and_scenes_page_row_icon',
                "assets/svg/Four_Dots.svg",
                size: 11,
                color: isActive ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FusionAppText(
                text: label,
                style: Theme.of(context).textTheme.l1SemiBold.copyWith(
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
