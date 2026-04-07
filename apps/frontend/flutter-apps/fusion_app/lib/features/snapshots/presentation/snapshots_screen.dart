import 'package:flutter/material.dart';
import 'package:fusion_app/features/snapshots/widgets/snapshot_card.dart';

class SnapshotsScreen extends StatelessWidget {

  const SnapshotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> items = [
      'Snapshot\nGroup 1',
      'Snapshot\nGroup 2',
      'Snapshot\nGroup 3',
      'Snapshot\nGroup 4',
      'Snapshot\nGroup 5',
      'Snapshot\nGroup 6',
      'Snapshot\nGroup 7',
    ];

    return GridView.builder(
      padding: EdgeInsets.only(left: 16,right: 16),
      itemCount: items.length,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3
      ),
      itemBuilder: (context, index) {
        return  SnapshotCard(title: items[index]);
      },
    );

  }

}
