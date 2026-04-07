// import 'package:flutter/material.dart';
// import 'package:fusion_app/features/project/presentation/configuration/widgets/db_slider.dart';
// import 'package:fusion_app/features/project/presentation/configuration/widgets/section_function.dart';
// import 'package:fusion_app/features/project/presentation/configuration/widgets/zone_title.dart';
// import 'package:fusion_app/features/zones/widgets/zone_header.dart';
// import 'package:fusion_lib/fusion_lib.dart';
//
// class ZonesTabScreen extends StatelessWidget {
//   const ZonesTabScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       shrinkWrap: true,
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 8),
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//           decoration: BoxDecoration(
//             color: context.colorScheme.elevation1,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.perm_data_setting_sharp,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//               SizedBox(width: 10),
//               Text(
//                 "Processing",
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onPrimary,
//                 ),
//               ),
//               SizedBox(width: 5),
//               Spacer(),
//               Icon(
//                 Icons.keyboard_arrow_down_outlined,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//             ],
//           ),
//         ),
//         Expanded(child: _ZonesList()),
//       ],
//     );
//   }
// }
//
//
// class ZonePanel extends StatelessWidget {
//   final String title;
//   final Color headerColor;
//   final bool expanded;
//
//   const ZonePanel({
//     super.key,
//     required this.title,
//     required this.headerColor,
//     this.expanded = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color:Color(0xFF1A1A18),
//       child: Column(
//         children: [
//           ZoneHeader(title: title, color: headerColor),
//
//           if (expanded) ...const [
//             SizedBox(height: 12),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 12),
//               child: FunctionSection(),
//             ),
//             SizedBox(height: 16),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 12),
//               child: _MeterRow(label: 'DM8F'),
//             ),
//             SizedBox(height: 12),
//             _MeterRow(label: 'DM8-SUB'),
//           ],
//         ],
//       ),
//     );
//   }
// }
//
// class _ZonesList extends StatelessWidget {
//   const _ZonesList();
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       //padding: const EdgeInsets.symmetric(horizontal: 16),
//       shrinkWrap: true,
//       children: const [
//         SizedBox(height: 12),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 8.0),
//           child: ZoneTitle('ZONES'),
//         ),
//
//         ZonePanel(
//           title: 'Reception',
//           headerColor: Color(0xFF2E3F63),
//           expanded: true,
//         ),
//
//         SizedBox(height: 12),
//
//         ZonePanel(title: 'Fitness', headerColor: Color(0xFF5A3428)),
//
//         SizedBox(height: 12),
//
//         ZonePanel(title: 'Weights', headerColor: Color(0xFF1F1F1F)),
//
//         SizedBox(height: 12),
//
//         ZonePanel(title: 'Studio Gold', headerColor: Color(0xFF1F5A43)),
//
//         SizedBox(height: 12),
//
//         ZonePanel(title: 'Studio Platinum', headerColor: Color(0xFF6A5A14)),
//       ],
//     );
//   }
// }
//
// class _MeterRow extends StatelessWidget {
//   final String label;
//
//   const _MeterRow({required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Text(label, style: const TextStyle(color: Colors.white)),
//             const Spacer(),
//             const Icon(Icons.volume_up, color: Colors.white54),
//             const SizedBox(width: 12),
//             const Icon(Icons.tune, color: Colors.white54),
//           ],
//         ),
//         const SizedBox(height: 6),
//         SizedBox(
//           child: HorizontalMeter(
//             value:-30 ??  0.0,
//             min: -60,
//             max: -0,
//             meterHeight: 30,
//             intervalGap: 12,
//             inactiveColor: context.colorScheme.elevation3,
//           ),
//         ),
//       ],
//     );
//   }
// }
