import 'package:flutter/material.dart';
import 'package:fusion_app/features/devices/models/device_model.dart';
import 'package:fusion_app/features/devices/widgets/device_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/fliter_chips.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/filter_bottom_sheet.dart';
import '../../shared/presentation/widgets/common/toast.dart';
class DevicesScreen extends StatelessWidget {
   DevicesScreen({super.key});
  Map<String, List<String>> selectedFilters = {};
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
              _openFilter(context,true);
            },
            child: Icon(Icons.search,color: context.colorScheme.textPrimary))
      ],),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FusionMultiFilterChips<String>(
              filterLabel: "Filter",
              items: const <String> [
                "Equipment Location",
                "Reception",
                "Cardio",
                "Weights",
              ],
              labelBuilder: (item) => item,
              labelTapped: (){
                _openFilter(context,false);
              },
              onChanged: (Set<dynamic> selected) {
                print(selected);
              },
            ),
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

  void _openFilter(context,bool focus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'FILTERS',
        focus: focus,
        categories: [
          FilterCategory(
            name: 'Zones',
            options: [
              FilterOption(name: 'Reception', id: 'reception',options: []),
              FilterOption(name: 'Fitness', id: 'fitness',options: [
                Option(name: 'Cardio'),
                Option(name: 'Weights'),
              ]),
              FilterOption(name: 'Studio Platinum', id: 'studio_platinum',options: []),
              FilterOption(name: 'Equipment Location', id: 'equipment_location',options: []),
            ],
          ),
          FilterCategory(
            name: 'Type',
            options: [
              FilterOption(name: 'DSP', id: 'dsp'),
              FilterOption(name: 'AMP', id: 'amp'),
            ],
          ),
          FilterCategory(
            name: 'Alerts',
            options: [
              FilterOption(name: 'Error', id: 'error'),
              FilterOption(name: 'Warning', id: 'warning'),
              FilterOption(name: 'Information', id: 'information'),
            ],
          ),
        ],
        initialSelectedFilters: selectedFilters,
        onApply: (filters) {
          // setState(() {
          //   selectedFilters = filters;
          // });
          // _fetchData(filters);
        },
        onClearFilters: () {
          // setState(() {
          //   selectedFilters.clear();
          // });
          // _fetchData({});
        },
      ),
    );
  }

}
