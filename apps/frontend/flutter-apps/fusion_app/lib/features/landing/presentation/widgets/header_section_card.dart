// import 'package:flutter/material.dart';
//
// class HeaderSection extends StatelessWidget {
//   final String title;
//   final Widget child;
//   const HeaderSection({this.title = 'Section Header',required this.child,super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Color(0xFF1A1A18),
//       padding: const EdgeInsets.only(top: 24,bottom: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16,right: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                  Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF7A7A7A))),
//                  Container(
//                   padding: const EdgeInsets.only(bottom: 1),
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: Colors.white, width: 0.8),
//                     ),
//                   ),
//                   child: const Text('View All'),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//           child
//         ],
//       ),
//     );
//   }
// }
//
//
//
