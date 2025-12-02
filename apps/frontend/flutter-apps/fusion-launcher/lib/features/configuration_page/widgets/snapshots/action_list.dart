import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ActionList extends StatelessWidget {
  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,

        border: Border(
          left: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          SectionHeader(
            title: 'Zones',
            trailing: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () {},
            ),
          ),

          /// Zones List
          // BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          //   builder: (BuildContext context, ProjectViewModelState state) {
          //     return _projectViewModel.zones.isEmpty
          //         ? Padding(
          //       padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
          //       child: FusionAppText(
          //         text: 'No zones added yet',
          //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          //           fontSize: 12,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     )
          //         : ReorderableListView.builder(
          //       shrinkWrap: true,
          //       physics: const ClampingScrollPhysics(),
          //       buildDefaultDragHandles: false,
          //       itemCount: _projectViewModel.zones.length,
          //       onReorder: (int oldIndex, int newIndex) {
          //         if (oldIndex < newIndex) newIndex -= 1;
          //         final String zoneToMove = _projectViewModel.zones[oldIndex].id;
          //         final String zoneAtNewIndex = _projectViewModel.zones[newIndex].id;
          //         _projectViewModel.reorderZones(
          //           zoneIdToMove: zoneToMove,
          //           zoneIdAtNewIndex: zoneAtNewIndex,
          //         );
          //         _projectViewModel.setSelectedDevice(
          //           zoneToMove,
          //           SelectedItemType.zone,
          //         );
          //       },
          //       itemBuilder: (BuildContext context, int index) {
          //         final Zone zoneData = _projectViewModel.zones[index];
          //         return ReorderableDragStartListener(
          //           key: ValueKey<String>(zoneData.id),
          //           index: index,
          //           child: ZoneCard(
          //             zoneId: zoneData.id,
          //             zoneName: zoneData.name,
          //             bgColor: zoneData.color,
          //             zoneData: zoneData,
          //           ),
          //         );
          //       },
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
