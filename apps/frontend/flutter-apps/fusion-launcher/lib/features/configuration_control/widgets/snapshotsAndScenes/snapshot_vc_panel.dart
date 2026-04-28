import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel — Virtual Controller (snapshot/scene tab).
class SnapshotVcPanel extends StatefulWidget {
  final String controllerID;
  final String vipAddress;
  final String? selectedSnapShotId;
  final bool isDesignMode;
  final WallControllerConfig config;
  const SnapshotVcPanel({
    super.key,
    this.isDesignMode = true,
    this.selectedSnapShotId,
    required this.controllerID,
    required this.vipAddress,
    required this.config,
  });

  @override
  State<SnapshotVcPanel> createState() => _SnapshotVcPanelState();
}

class _SnapshotVcPanelState extends State<SnapshotVcPanel> {
  WallController? controller;
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
            semanticId:
                FusionTestKeys
                    .instance
                    .snapshotAndScenesTabVirtualControllerHeader,
            title: 'VIRTUAL CONTROLLER',
          ),
          Expanded(child: _buildContent(context, getWallPages())),
        ],
      ),
    );
  }

  List<SnapshotsModel> getWallPages() {
    final WallControllerConfig config = widget.config;

    controller = config.controllers.firstWhere(
      (WallController ctrl) => ctrl.id == widget.controllerID,
    );

    final List<SnapshotsModel> filteredSnapshots = <SnapshotsModel>[];

    if (controller != null) {
      final List<WallPages> pages = controller!.pages;
      final List<WallPageSnapshot> wallPageSnapshots =
          pages
              .where(
                (WallPages page) => page.pageId == widget.selectedSnapShotId,
              )
              .expand(
                (WallPages page) => page.snapshotsList,
              )
              .toList();

      filteredSnapshots.addAll(
        wallPageSnapshots
            .map(
              (WallPageSnapshot snap) => SnapshotsModel(
                id: snap.id,
                name: snap.name,
              ),
            )
            .toList(),
      );
    }

    return filteredSnapshots;
  }

  Widget _buildContent(BuildContext context, List<SnapshotsModel> snapshots) {
    // String title;
    // List<SnapshotsModel> snapshots;
    //
    // if (selectedSnapshotPageId != null) {
    //   final WallPages? page = _findSnapshotPage(pages, selectedSnapshotPageId!);
    //   title = page?.name ?? 'Snapshot Page';
    //   snapshots = _resolveSnapshots(state, page);
    // } else if (selectedSceneSetId != null) {
    //   final SceneSetModel? sceneSet = _findSceneSet(widget.sceneSets,selectedSceneSetId!);
    //   title = sceneSet?.name ?? 'Scene';
    //   snapshots = widget.snapshotsInSceneSets[selectedSceneSetId] ?? <SnapshotsModel>[];
    // } else {
    //   title = 'Snapshots';
    //   snapshots = <SnapshotsModel>[];
    // }

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
                  text: "title",
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
                    onSelected: (String snapShotId) async {
                      final SnapshotActivateService snapshotActivateService =
                          fusionLibLocator<SnapshotActivateService>();
                      if (true) {
                        try {
                          final ResponseCallback<bool> result =
                              await snapshotActivateService.activateSnapshot(
                                vip: widget.vipAddress,
                                name: snapShotId,
                              );
                          if (context.mounted) {
                            if (result.success) {
                              FusionToast.success(
                                context,
                                message: "Snapshot recalled successfully",
                              );
                            } else {
                              FusionToast.error(
                                context,
                                message: "Failed to recall snapshot",
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            FusionToast.error(
                              context,
                              message: "Failed to recall snapshot",
                            );
                          }
                        }
                      }
                    },
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
