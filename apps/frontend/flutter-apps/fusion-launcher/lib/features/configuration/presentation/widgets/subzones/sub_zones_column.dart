// import 'package:flutter/material.dart';
//
// import '../../../../../core/constants.dart';
// import '../../../entities/models.dart';
// import 'sub_zone_widget.dart';
//
// class SubZonesColumn extends StatelessWidget {
//   final Zone zone;
//   final void Function(Zone) onZoneChanged;
//   final VoidCallback onClose;
//
//   const SubZonesColumn({
//     super.key,
//     required this.zone,
//     required this.onZoneChanged,
//     required this.onClose,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: AppLayout.sectionWidth,
//       margin: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.blueGrey.withOpacity(0.5)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             // Header
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//               decoration: BoxDecoration(
//                 color: AppColors.warningSoft,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Row(
//                 children: <Widget>[
//                   IconButton(
//                     onPressed: onClose,
//                     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '${zone.name} - Sub Zones',
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
//                     onPressed: _addSubZone,
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             // List
//             Expanded(
//               child:
//                   zone.subZones.isEmpty
//                       ? const Center(
//                         child: Text(
//                           'No sub zones created yet\nClick + to add a sub zone',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey, fontSize: 12),
//                         ),
//                       )
//                       : ListView.builder(
//                         itemCount: zone.subZones.length,
//                         itemBuilder: (BuildContext ctx, int i) {
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 8),
//                             child: SubZoneWidget(
//                               subZone: zone.subZones[i],
//                               onSubZoneChanged: (SubZone updated) {
//                                 final List<SubZone> list = <SubZone>[...zone.subZones]..[i] = updated;
//                                 onZoneChanged(zone.copyWith(subZones: list));
//                               },
//                               onDelete: () {
//                                 final List<SubZone> list = <SubZone>[...zone.subZones]..removeAt(i);
//                                 onZoneChanged(zone.copyWith(subZones: list));
//                               },
//                             ),
//                           );
//                         },
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _addSubZone() {
//     final SubZone newSub = SubZone(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       name: 'Sub Zone ${zone.subZones.length + 1}',
//       processingChain: ProcessingChain(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//       ),
//       circuits: const <Circuit>[],
//     );
//     onZoneChanged(zone.copyWith(subZones: <SubZone>[...zone.subZones, newSub]));
//   }
// }
