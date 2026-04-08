import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/commission/presentation/network/search/searching_screen.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceSearchingScreen extends StatefulWidget {
  const DeviceSearchingScreen({super.key});

  @override
  State<DeviceSearchingScreen> createState() => _DeviceSearchingScreenState();
}

class _DeviceSearchingScreenState extends State<DeviceSearchingScreen> {

  @override
  void initState() {
    // TODO: implement initState

    Future.delayed(Duration(seconds: 3),(){
      isSearching=false;
      setState(() {

      });
    });

    // Future.delayed(Duration(seconds: 6),(){
    //   // TODO: Bluetooth flow
    //   if (!mounted) return;
    //   Navigator.pushNamed(
    //       context,
    //       Routes.configureVIP
    //   );
    //
    // });
    //
    // Future.delayed(Duration(seconds: 3),(){
    //   showModalBottomSheet(
    //     context: context,
    //     constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
    //     barrierColor: Colors.transparent,
    //     isScrollControlled: false,
    //     builder: (context) {
    //       return const BottomBluetoothSheet();
    //     },
    //   );
    // });

    super.initState();
  }

  bool isSearching = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Configure Network'),
        body: isSearching ? SearchingScreen() :
        CommonEmptyState(
            icon: Icons.search_off,
            title: 'Oops! We couldn’t detect any Fusion network',
            subtitle: 'Make sure you are connected to right network',
        action: CustomButton(
          enabled: ValueNotifier(true),
          buttonText: 'Retry',
          onPressed: () {
              setState(() {
                isSearching=true;
              });
              Future.delayed(Duration(seconds: 3),(){
                Navigator.pushReplacementNamed(context, Routes.selectHardware);
              });

          }
        )
      )),
    );
  }
}


// class BottomBluetoothSheet extends StatelessWidget {
//   const BottomBluetoothSheet({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 24,horizontal: 8),
//       decoration: BoxDecoration(
//         color: context.colorScheme.elevation1,
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(24),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: context.colorScheme.elevation1,
//             blurRadius: 20,
//             offset: Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           // 🔹 Title row
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: context.colorScheme.elevation2,
//                   ),
//                     child: Icon(Icons.bluetooth, color:  context.colorScheme.onPrimary,size: 24,)),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(width: 12),
//                       Text(
//                         'Configure Wireless Devices?',
//                         style: Theme.of(context).textTheme.titleMedium!.copyWith(
//                           fontWeight: FontWeight.w700,
//                           color: context.colorScheme.textPrimary,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                        Text(
//                         'You can add and configure wireless devices',
//                         style: Theme.of(context).textTheme.labelMedium!.copyWith(
//                           fontWeight: FontWeight.w400,
//                           color: context.colorScheme.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//
//               ],
//             ),
//           ),
//           SizedBox(height: 24),
//           CustomButton(
//             enabled:  ValueNotifier(true),
//             buttonText: 'Connect Via Bluetooth',
//             onPressed: () {
//               // TODO: Bluetooth flow
//               Navigator.pushNamed(
//                   context,
//                   Routes.configureSearchBluetooth
//               );
//             },
//           )
//         ],
//       ),
//     );
//   }
// }
