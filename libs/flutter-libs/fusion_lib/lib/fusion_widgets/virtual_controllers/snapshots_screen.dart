import 'package:flutter/material.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/appbar/mobile_app_bar.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/widgets/snapshot_card.dart';

class SnapshotsScreen extends StatefulWidget {
  final List<SnapshotsModel> snapshots;
  final Function? onSelected;
  final String vipAddress;
  final String? snapshotId;
  final String? sceneSetId;
  const SnapshotsScreen({
    super.key,
    this.snapshots = const [],
    this.onSelected,
    required this.vipAddress,
    this.sceneSetId,
    this.snapshotId,
  });

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  int? selectedIndex;
  int? previousIndex;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.snapshots.length,
      itemBuilder: (context, index) {
        SnapshotsModel snapshot = widget.snapshots[index];

        return SnapshotSelectionCard(
          title: snapshot.name,
          label: "snapshot.label",
          isLoading: isLoading,
          isSelected: selectedIndex == index,
          onTap: () {
            isLoading = true;
            selectedIndex = index;
            setState(() {});
            Future.delayed(Duration(seconds: 1),(){
              onSelected(snapshot.id,index);
            });

          },
        );
      },
    );
  }

  onSelected(String snapShotId,index) async {

    if (widget.vipAddress.isNotEmpty && snapShotId.isNotEmpty) {
      try {
        ResponseCallback<bool>? result;
        if (widget.snapshotId!=null) {
          result = await fusionLibLocator<SnapshotActivateService>()
              .activateSnapshot(
                vip: widget.vipAddress,
                name: snapShotId,
              );
        } else {
          result = await fusionLibLocator<SceneSetActivateService>()
              .activateSceneSet(
                vip: widget.vipAddress,
                sceneId: snapShotId,
                setId: widget.sceneSetId ?? "",
              );
        }
        if (context.mounted) {
          if (result!.success) {
            previousIndex = index;
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
        isLoading = false;
        setState(() {});
      } catch (e) {
        if (context.mounted) {
          isLoading = false;
          selectedIndex = previousIndex;
          setState(() {});
          FusionToast.error(
            context,
            message: "Failed to recall snapshot",
          );
        }
      }
    }
  }
}
