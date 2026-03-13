import 'package:flutter/material.dart';
import 'package:fusion_app/features/snapshots/models/snapshot_model.dart';
import 'package:fusion_app/features/snapshots/widgets/snapshot_selection_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SnapshotListScreen extends StatefulWidget {
  const SnapshotListScreen({super.key});

  @override
  State<SnapshotListScreen> createState() => _SnapshotListScreenState();
}

class _SnapshotListScreenState extends State<SnapshotListScreen> {
  int? selectedIndex;
  final List<SnapshotModel> snapshots = [
    const SnapshotModel(title: "Morning", label: "Label"),
    const SnapshotModel(title: "Afternoon", label: "Label"),
    const SnapshotModel(title: "Yoga Session 1", label: "Label"),
    const SnapshotModel(title: "Yoga Session 2", label: "Label"),
    const SnapshotModel(title: "Zumba", label: "Label"),
    const SnapshotModel(title: "Aerobics", label: "Label"),
    const SnapshotModel(title: "Evening", label: "Label"),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: context.colorScheme.primaryBlack,
        title: Text(
          "Snapshot Group 1",
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [

          /// List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshots.length,
              itemBuilder: (context, index) {
                final snapshot = snapshots[index];

                return SnapshotSelectionCard(
                  title: snapshot.title,
                  label: snapshot.label,
                  isSelected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),

          /// Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.elevation2,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}