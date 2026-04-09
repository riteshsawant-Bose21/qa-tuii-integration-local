//
// import 'package:flutter/material.dart';
// import 'package:fusion_app/features/project/presentation/configuration/widgets/item_function.dart';
//
// class FunctionSection extends StatelessWidget {
//   const FunctionSection({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: const [
//             Text('FUNCTION', style: TextStyle(color: Colors.white54)),
//             Spacer(),
//             Icon(Icons.edit, color: Colors.white54),
//           ],
//         ),
//         const SizedBox(height: 8),
//         FunctionItem(title: 'Source Select'),
//         const SizedBox(height: 8),
//         FunctionItem(title: 'Wireless Mic', badge: 'P1'),
//         const SizedBox(height: 8),
//         FunctionItem(title: 'Select', badge: 'P2', disabled: true),
//         const SizedBox(height: 8),
//         FunctionItem(title: 'Selected', badge: '3'),
//       ],
//     );
//   }
// }