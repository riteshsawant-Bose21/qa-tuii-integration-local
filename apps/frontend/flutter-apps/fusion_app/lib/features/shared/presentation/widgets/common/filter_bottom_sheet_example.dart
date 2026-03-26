// import 'package:flutter/material.dart';
// import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';
//
// /// Example usage of the FilterBottomSheet widget
// ///
// /// This file demonstrates how to integrate and use the FilterBottomSheet
// /// in your application.
// class FilterBottomSheetExample extends StatefulWidget {
//   const FilterBottomSheetExample({Key? key}) : super(key: key);
//
//   @override
//   State<FilterBottomSheetExample> createState() =>
//       _FilterBottomSheetExampleState();
// }
//
// class _FilterBottomSheetExampleState extends State<FilterBottomSheetExample> {
//   Map<String, List<String>> selectedFilters = {};
//
//   void _showFilterBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => FilterBottomSheet(
//         title: 'FILTERS',
//         categories: [
//           FilterCategory(
//             name: 'Zones',
//             options: [
//               FilterOption(name: 'Zone 1', id: 'zone_1'),
//               FilterOption(name: 'Zone 2', id: 'zone_2'),
//               FilterOption(name: 'Zone 3', id: 'zone_3'),
//             ],
//           ),
//           FilterCategory(
//             name: 'Type',
//             options: [
//               FilterOption(name: 'Reception', id: 'reception'),
//               FilterOption(name: 'Fitness', id: 'fitness'),
//               FilterOption(name: 'Cardio', id: 'cardio'),
//               FilterOption(name: 'Weights', id: 'weights'),
//             ],
//           ),
//           FilterCategory(
//             name: 'Alerts',
//             options: [
//               FilterOption(name: 'Studio Platinum', id: 'studio_platinum'),
//               FilterOption(name: 'Equipment location', id: 'equipment_location'),
//             ],
//           ),
//         ],
//         initialSelectedFilters: selectedFilters,
//         onApply: (selectedFilters) {
//           setState(() {
//             this.selectedFilters = selectedFilters;
//           });
//           // Handle applying filters - typically fetch data with these filters
//           print('Applied filters: $selectedFilters');
//         },
//         onClearFilters: () {
//           setState(() {
//             selectedFilters.clear();
//           });
//           print('Filters cleared');
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Filter Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: _showFilterBottomSheet,
//               child: const Text('Open Filter'),
//             ),
//             const SizedBox(height: 24),
//             if (selectedFilters.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Selected Filters:'),
//                     const SizedBox(height: 8),
//                     ...selectedFilters.entries.map((entry) {
//                       if (entry.value.isEmpty) return const SizedBox.shrink();
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: Text('${entry.key}: ${entry.value.join(", ")}'),
//                       );
//                     }).toList(),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
