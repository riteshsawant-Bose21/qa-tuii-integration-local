import 'package:flutter/material.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_app/features/commission/widgets/available_bluetooth_devices.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigureBluetoothSearchingScreen extends StatefulWidget {
  const ConfigureBluetoothSearchingScreen({super.key});

  @override
  State<ConfigureBluetoothSearchingScreen> createState() => _ConfigureBluetoothSearchingScreenState();
}

class _ConfigureBluetoothSearchingScreenState extends State<ConfigureBluetoothSearchingScreen> {
  List<BluetoothDeviceModel> devices = [];
  bool devicesFound=false;
  @override
  void initState() {
    // TODO: implement initState

    Future.delayed(Duration(seconds: 3),(){
      setState(() {
        devicesFound=true;

       devices = [
          const BluetoothDeviceModel(name: 'Fusion Mini FM6',ipAddress:'192.168.0.105', ),
          const BluetoothDeviceModel(name: 'Power Smart 8300',ipAddress:'192.168.0.106',),
        ];
      });
    });

    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: 'Configure Bluetooth'),
      body: devicesFound ? BluetoothAvailableScreen(devices: devices) : getSearchScreen()
    );
  }

  Widget getSearchScreen(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            /// Bluetooth Icon
             Icon(
              Icons.bluetooth,
              size: 48,
              color:context.colorScheme.onPrimary,
            ),

            const Spacer(),

            /// Title
             Text(
              'Hold on, searching for Bluetooth devices',
              textAlign: TextAlign.center,
              style:  Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            /// Subtitle
             Text(
              'Make sure you Bluetooth devices are turned on',
              textAlign: TextAlign.center,
              style:  Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w400,
                color: context.colorScheme.textSecondary,
              ),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }

}
