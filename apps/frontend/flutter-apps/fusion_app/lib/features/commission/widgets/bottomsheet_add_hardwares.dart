import 'package:flutter/material.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_app/features/commission/widgets/hardware_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SheetContent extends StatelessWidget {
  final ValueNotifier<int?> selectedIndex;
  final Function? onSelected;
   SheetContent({super.key, required this.selectedIndex,this.onSelected});
  final ValueNotifier<bool> selectedHardware = ValueNotifier(false);


  List<BluetoothDeviceModel>devices = [
    const BluetoothDeviceModel(name: 'Fusion Mini FM6',ipAddress:'192.168.0.105', ),
    const BluetoothDeviceModel(name: 'Power Smart 8300',ipAddress:'192.168.0.106',),
  ];

  @override
  Widget build(BuildContext context) {

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    Text(
                      'Hardwares on the network',
                      style:Theme.of(context).textTheme.b2Medium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select the hardware to map the devices to the unassigned area. '
                          'You can use Blink to confirm the correct device',
                      style:Theme.of(context).textTheme.b3Regular.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),



                ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: devices.length,
                    itemBuilder: (ctx,i){
                      return HardwareItem(
                        onSelected: (i){
                          selectedHardware.value = !selectedHardware.value;
                        },
                        index: i,
                        title: devices[i].name,
                        ipAddress: devices[i].ipAddress!,
                        selectedIndex: selectedIndex,
                      );
                    },
                    separatorBuilder:   (ctx,i){
                      return  const SizedBox(height: 12);
                    }
                ),

                const SizedBox(height: 20),
                CustomButton(
                  backGroundColor: context.colorScheme.elevation1,
                  isNeumorphic: true,
                  enabled: ValueNotifier(true),
                  onPressed: (){
                    onSelected!();
                    Navigator.pop(context);
                  },
                  buttonText:'Continue',
                ),
                const SizedBox(height: 40),
                // Center(
                //   child: Text(
                //     'Add a wireless device',
                //     style: TextStyle(
                //       fontSize: 16,
                //       fontWeight: FontWeight.w600,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap:() =>  Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:context.colorScheme.elevation1,
              shape: BoxShape.circle,
              boxShadow:  [
                BoxShadow(
                  color: context.colorScheme.elevation1,
                  blurRadius: 12,
                ),
              ],
            ),
            child:  Icon(Icons.close, color:  context.colorScheme.onPrimary),
          ),
        )
      ],
    );
  }
}