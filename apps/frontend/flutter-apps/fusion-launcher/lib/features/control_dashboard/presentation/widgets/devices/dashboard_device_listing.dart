import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'dashboard_device_card.dart';
import 'dashboard_device_table_header.dart';

class DashboardDeviceListing extends StatelessWidget {
  const DashboardDeviceListing({super.key});

  List<HardwareComponent> get fusionDevice {
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    final List<HardwareComponent> endpoints = serviceLocator<ProjectViewModel>().fusionEndpoints;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers, ...endpoints];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          DashboardSectionHeader(
            title: "DEVICES",
            showViewAll: true,
            onViewAll: () {},
          ),
          const SizedBox(height: 16),
          const DashboardDeviceTableHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: fusionDevice.length,
              itemBuilder: (BuildContext context, int index) {
                final HardwareComponent device = fusionDevice[index];
                return DashboardDeviceCard(
                  device: device,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
