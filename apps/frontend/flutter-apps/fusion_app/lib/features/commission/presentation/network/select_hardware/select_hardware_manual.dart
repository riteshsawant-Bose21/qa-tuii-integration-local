import 'package:flutter/material.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_app/features/commission/widgets/hardware_item.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SelectHardwareManual extends StatefulWidget {
  const SelectHardwareManual({super.key});

  @override
  State<SelectHardwareManual> createState() => _SelectHardwareManualState();
}

class _SelectHardwareManualState extends State<SelectHardwareManual> {
  final ValueNotifier<bool> selectedHardware = ValueNotifier(false);

  List<BluetoothDeviceModel>devices = [
    const BluetoothDeviceModel(name: 'Power Smart 8300'),
    const BluetoothDeviceModel(name: 'Fusion Mini FM6'),
    const BluetoothDeviceModel(name: 'Power Smart 8300'),
    const BluetoothDeviceModel(name: 'Fusion Mini FM6'),
    const BluetoothDeviceModel(name: 'Power Smart 8300'),
    const BluetoothDeviceModel(name: 'Fusion Mini FM6'),
  ];
  final ValueNotifier<int?> selectedIndex = ValueNotifier(0);

  bool shouldShowError = true;
  @override
  Widget build(BuildContext context) {
    return  ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: devices.length,
        itemBuilder: (ctx,i){
          return HardwareItem(
            onSelected: (i){

              selectedHardware.value= !selectedHardware.value;
            },
            index: i,
            title: devices[i].name,
            ipAddress: devices[i].ipAddress,
            selectedIndex: selectedIndex,
          );
        },
        separatorBuilder:   (ctx,i){
          return  const SizedBox(height: 12);
        }
    );
  }
}
