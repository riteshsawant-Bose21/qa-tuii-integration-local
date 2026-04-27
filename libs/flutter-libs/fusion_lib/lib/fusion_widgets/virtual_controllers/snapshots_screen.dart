import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/appbar/mobile_app_bar.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/widgets/snapshot_card.dart';


class SnapshotsScreen extends StatefulWidget {
  final List<SnapshotsModel> snapshots;
  const SnapshotsScreen({super.key,this.snapshots=const []});

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  int? selectedIndex;

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.snapshots.length,
      itemBuilder: (context, index) {
        SnapshotsModel snapshot = widget.snapshots[index];

        return SnapshotSelectionCard(
          title: snapshot.name,
          label: "snapshot.label",
          isSelected: selectedIndex == index,
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
          },
        );
      },
    );
  }
}