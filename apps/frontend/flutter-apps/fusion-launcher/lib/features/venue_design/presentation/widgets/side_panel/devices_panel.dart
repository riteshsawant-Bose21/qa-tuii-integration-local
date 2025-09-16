import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class DevicesPanel extends StatefulWidget {
  final ExpansibleController productsController;

  const DevicesPanel({
    super.key,
    required this.productsController,
  });

  @override
  State<DevicesPanel> createState() => _DevicesPanelState();
}

class _DevicesPanelState extends State<DevicesPanel> {
  void goToDevicePlacementMode() {
    widget.productsController.expand();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(left: 10),
          // color: Colors.grey[50],
          child: Column(
            children: <Widget>[
              _buildSubItem(
                Icons.speaker,
                'Speaker',
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 0,
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(0);
                },
              ),
              _buildSubItem(
                Icons.mic,
                'Sources',
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 1,
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(1);
                },
              ),

              _buildSubItem(
                Icons.hub_outlined,
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 2,
                'Endpoints',
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(2);
                },
              ),
              _buildSubItem(
                Icons.amp_stories,
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 3,
                'Amplifiers',
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(3);
                },
              ),
              _buildSubItem(
                Icons.dns_outlined,
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 4,
                'DSPs',
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(4);
                },
              ),
              _buildSubItem(
                Icons.tune,
                'Controllers',
                isSelected: serviceLocator<ProjectViewModel>().currentDeviceTypeIndex == 5,
                onTap: () {
                  goToDevicePlacementMode();
                  serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(5);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    required Function() onTap,
  }) {
    return Stack(
      children: <Widget>[
        Container(
          // margin: const EdgeInsets.only(bottom: 2),
          //if selected is true change background color to light blue
          color: isSelected ? Colors.grey[100] : Colors.transparent,

          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            leading: Icon(
              icon,
              size: 14,
              color: Colors.black87,
            ),
            title: FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            // trailing: const Icon(
            //   Icons.add,
            //   size: 14,
            //   color: Colors.black87,
            // ),
            onTap: () {
              onTap();
            },
          ),
        ),
        if (isSelected)
          Container(
            width: 4,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
