import 'package:flutter/material.dart';
import 'package:fusion_app/features/devices/models/device_model.dart';
import 'package:fusion_app/features/devices/widgets/device_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/fliter_chips.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/toast.dart';
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = [
      const DeviceModel(
        title: 'PSM8300-1',
        subtitle: 'Powersmart8300',
        temperature: '39°C',
        cpu: 80,
        disk: 84,
        alertType: DeviceAlertType.critical,
        alertText: 'Open Circuit Fault',
      ),
      const DeviceModel(
        title: 'Fusion Mini 6',
        subtitle: 'FusionMini6',
        temperature: '46°C',
        cpu: 43,
        disk: 70,
        alertType: DeviceAlertType.warning,
        alertText: 'High Temperature Warning',
      ),
      const DeviceModel(
        title: 'PSM8300-2',
        subtitle: 'Powersmart8300',
        temperature: '21°C',
        cpu: 55,
        disk: 33,
      ),
      const DeviceModel(
        title: 'FusionMini8Y',
        subtitle: 'FusionMini8Y',
        temperature: '21°C',
        cpu: 55,
        disk: 33,
      ),
    ];

    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: "Devices",actions: [
        GestureDetector(
            onTap: (){

            },
            child: Icon(Icons.search,color: context.colorScheme.textPrimary))
      ],),
      body: Column(
        children: [
          FusionMultiFilterChips<String>(
            items: const <String> [
              "Filter",
              "Equipment Location",
              "Reception",
              "Cardio",
              "Weights",
            ],
            labelBuilder: (item) => item,
            onChanged: (Set<dynamic> selected) {
              print(selected);
            },
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              shrinkWrap: true,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DeviceCard(device: devices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
