import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';
import 'package:fusion_app/features/wall_controllers/models/wall_controller_model.dart';
import 'package:fusion_app/features/wall_controllers/widgets/wall_controller_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

class WallControllersScreen extends StatefulWidget {
  const WallControllersScreen({super.key});

  @override
  State<WallControllersScreen> createState() => _WallControllersScreenState();
}

class _WallControllersScreenState extends State<WallControllersScreen> {
   List<WallController> controllers =[];

  @override
  void initState() {


    Future.delayed(Duration(seconds: 3),(){
      controllers = [
        const WallController(
          deviceName: "Device 01",
          deviceModel: "Control Pal Pro",
          location: "EQUIPMENT LOCATION",
          isOnline: true,
        ),
        const WallController(
          deviceName: "Device 02",
          deviceModel: "Control Pal Pro",
          location: "EQUIPMENT LOCATION",
          isOnline: true,
        ),
        const WallController(
          deviceName: "Device 03",
          deviceModel: "Control Pal Pro",
          location: "EQUIPMENT LOCATION",
          isOnline: false,
        ),
      ];

      setState(() {

      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: "Wall Controllers",actions: [
        controllers.isNotEmpty ?  GestureDetector(
            onTap: (){
              Navigator.pushNamed(context, Routes.qrScannerPage);
            },
            child: Icon(
                Icons.qr_code_scanner_outlined,
                size: 16,
                color: context.colorScheme.iconWhite
            )
        ) : SizedBox.shrink()
      ],),
      body:controllers.isEmpty ?  getEmptyState(): getItems()
    );
  }

  Widget getItems(){
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controllers.length,
      itemBuilder: (context, index) {
        final device = controllers[index];

        return WallControllerCardItem(
          onTap: (){
            Navigator.pushNamed(context, Routes.controlPalPage);
          },
          deviceName: device.deviceName,
          deviceModel: device.deviceModel,
          location: device.location,
          isOnline: device.isOnline,
        );
      },
    );
  }

   Widget getEmptyState(){

     return CommonEmptyState(
       icon: Icons.tune,
       title: "No Wall Controllers",
       subtitle:"You don’t have any Wall Controllers yet.\nAdd one to get started.",
       action: Container(
         child: CustomButton(
           padding: EdgeInsets.zero,
           bottomPadding: 0,
           enabled: ValueNotifier(true),
           buttonText: 'Scan QR for Wall Controllers',
           onPressed: () {
             Navigator.pushNamed(context, Routes.qrScannerPage);
           },
         ),
       ),
     );
   }
}
