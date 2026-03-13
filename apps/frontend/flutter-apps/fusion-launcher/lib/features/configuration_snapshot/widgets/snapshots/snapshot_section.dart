import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/snapshot_list.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/snapshots/SnapshotsKeys.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../configuration_page/widgets/section_header.dart';
import '../../viewModel/snapshot_viewmodel/config_snapshots_state.dart';
import '../../viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';

class SnapshotSet extends StatefulWidget {
  const SnapshotSet({super.key});

  @override
  State<SnapshotSet> createState() => _SnapshotSetState();
}

class _SnapshotSetState extends State<SnapshotSet> {
  ConfigSnapshotsViewmodel get _configSnapshotsViewmodel => context.read<ConfigSnapshotsViewmodel>();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.snpsection),
      child: BlocBuilder<ConfigSnapshotsViewmodel, ConfigSnapshotsState>(
        builder: (
          BuildContext context,
          ConfigSnapshotsState configSnapshotsState,
        ) {
          return Column(
            children: <Widget>[
              SectionHeader(
                semanticLabel: 'snapshots',
                title: 'Snapshots',
                trailing: GestureDetector(
                  onTap: () {
                    _configSnapshotsViewmodel.addSnapshot();
                    FusionToast.success(
                      context,
                      message: "Snapshot created",
                    );
                  },
                  child: Icon(
                    semanticLabel: FusionTestKeys.instance.snapshotheadericon,
                    Icons.add_sharp,
                    size: 16,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ),
              DragTarget<SnapshotsModel>(
                onWillAcceptWithDetails: (
                  DragTargetDetails<SnapshotsModel> details,
                ) {
                  return _configSnapshotsViewmodel.shouldAcceptDropOnSnapshots();
                },
                onLeave: (SnapshotsModel? data) {},
                onAcceptWithDetails: (
                  DragTargetDetails<SnapshotsModel> details,
                ) {
                  _configSnapshotsViewmodel.handleDropOnSnapshots(
                    details.data,
                  );
                },
                builder: (
                  BuildContext context,
                  List<SnapshotsModel?> candidateData,
                  List<dynamic> rejectedData,
                ) {
                  final bool isHovered = candidateData.isNotEmpty && configSnapshotsState.isDraggingFromScenes;
                  return SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.snpsectiondata),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isHovered
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1)
                                : context.colorScheme.elevation1,
                        border:
                            isHovered
                                ? Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 2,
                                )
                                : Border.symmetric(
                                  vertical: BorderSide(
                                    color: context.colorScheme.elevation2,
                                    width: 1,
                                  ),
                                ),
                      ),
                      height: configSnapshotsState.sourcesHeight,
                      child: SingleChildScrollView(
                        child: _buildSnapshotsList(
                          context,
                          configSnapshotsState,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSnapshotsList(BuildContext context, ConfigSnapshotsState state) {
    final List<SnapshotsModel> snapShotList = state.snapshots;
    if (snapShotList.isEmpty) {
      return SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.snpsectiondataemty),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.only(top: state.sourcesHeight * 0.4),
          child: FusionAppText(
            text: 'No snapshots available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return SnapshotList(
      snapShotList: snapShotList,
      onDelete: (String sceneId) {
        _configSnapshotsViewmodel.deleteSnapshot(sceneId);
        FusionToast.success(context, message: "Snapshot deleted successfully");
      },
      selectedSnapshotId: state.selectedSnapshotId,
      onSelect: (String sceneId) {
        _configSnapshotsViewmodel.selectSnapshot(sceneId);
      },
      onDuplicate: (String sceneId) {
        _configSnapshotsViewmodel.duplicateSnapshot(sceneId);
        FusionToast.success(
          context,
          message: "Snapshot duplicated successfully",
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        _configSnapshotsViewmodel.reorderSnapshots(oldIndex, newIndex);
      },
      onDragStarted: (String sceneId) {
        _configSnapshotsViewmodel.startDrag(sceneId, DragSection.snapshots);
      },
      onDragEnd: () {
        _configSnapshotsViewmodel.endDrag();
      },
      draggingSnapshotId: state.draggingSnapshotId,
      onRenameSave: (String value, SnapshotsModel newSnapshot) {
        _configSnapshotsViewmodel.updateSnapshot(newSnapshot);
      },
    );
  }
}
