import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel — Virtual Controller (snapshot/scene tab).
class SnapshotVcPanel extends StatefulWidget {
  final String controllerID;
  final String vipAddress;
  final String? selectedSnapShotId;
  final String? selectedSceneSetId;
  final bool isDesignMode;
  final WallControllerConfig config;
  const SnapshotVcPanel({
    super.key,
    this.isDesignMode = true,
    this.selectedSnapShotId,
    this.selectedSceneSetId,
    required this.controllerID,
    required this.vipAddress,
    required this.config,
  });

  @override
  State<SnapshotVcPanel> createState() => _SnapshotVcPanelState();
}

class _SnapshotVcPanelState extends State<SnapshotVcPanel> {
  WallController? controller;
  WallPages? wallPages;
  bool isLoading = false;
  int? selectedIndex;
  //final List<WallPages> _pages = <WallPages>[];
  // @override
  // void initState() {
  //
  //
  //   super.initState();
  //   final List<WallPages> _pages = getWallPages();
  // }
  //
  // @override
  // void didUpdateWidget(covariant SnapshotVcPanel oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //
  //   final List<WallPages> zones = getWallPages();
  //
  // }

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
          PanelSectionHeader(
            semanticId: FusionTestKeys.instance.snapshotAndScenesTabVirtualControllerHeader,
            title: 'VIRTUAL CONTROLLER',
          ),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  List<SnapshotsModel> getWallPages() {
    final WallControllerConfig config = widget.config;

    controller = config.controllers.firstWhereOrNull(
      (WallController ctrl) => ctrl.id == widget.controllerID,
    );

    final List<SnapshotsModel> filteredSnapshots = <SnapshotsModel>[];

    if (controller != null) {
      final List<WallPages> pages = controller!.pages;
      final String filterId = widget.selectedSnapShotId ?? widget.selectedSceneSetId ?? "";
      final WallPages? filteredPages = pages.firstWhereOrNull(
        (WallPages page) => page.pageId == filterId,
      );

      if (filteredPages != null) {
        wallPages = filteredPages;
        filteredSnapshots.addAll(
          filteredPages.snapshotsList
              .map(
                (WallPageSnapshot snap) => SnapshotsModel(
                  id: snap.id,
                  name: snap.name,
                ),
              )
              .toList(),
        );
      } else {
        wallPages = null;
      }
      selectedIndex = null;
    }

    return filteredSnapshots;
  }

  Widget _buildContent(BuildContext context) {
    final List<SnapshotsModel> snapshots = getWallPages();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryBlack,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Title ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: FusionAppText(
                  text: wallPages?.name ?? "",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),

              // ── Snapshot list ─────────────────────────────────────────
              if (snapshots.isEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: FusionAppText(
                      text:
                          'No snapshots linked to this page'
                          'Select a page or scene to view',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SnapshotsScreen(
                    vipAddress: widget.vipAddress,
                    sceneSetId: widget.selectedSceneSetId,
                    snapshotId: widget.selectedSnapShotId,
                    snapshots: snapshots,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
