// import 'package:flutter/material.dart';
// import 'package:fusion_lib/fusion_lib.dart';
//
// class NoNotificationsView extends StatelessWidget {
//   const NoNotificationsView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       bottom: false,
//       child: Scaffold(
//         backgroundColor: context.colorScheme.primaryBlack,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//
//                 /// Icon Circle
//                 CircleAvatar(
//                   radius: 48,
//                   backgroundColor: context.colorScheme.elevation2,
//                   child: Icon(Icons.notifications_none_outlined,
//                       color: context.colorScheme.iconDefault,size: 42),
//                 ),
//
//
//                 const SizedBox(height: 32),
//
//                 /// Title
//                 Text(
//                   "No Notifications Yet",
//                   textAlign: TextAlign.center,
//                   style:Theme.of(context).textTheme.h5BoldMobile.copyWith(
//                     fontWeight: FontWeight.w700,
//                     color: context.colorScheme.textPrimary,
//                   ),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 /// Subtitle
//                 Text(
//                   "You're all caught up! We'll notify you when there's something new",
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.b3Regular!.copyWith(
//                     fontWeight: FontWeight.w400,
//                     color: context.colorScheme.textBody,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }