import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                onTap: () {
                  goToDevicePlacementMode();
                },
              ),
              _buildSubItem(
                Icons.mic,
                'Sources',
                onTap: () {},
              ),
              _buildSubItem(
                Icons.tune,
                'Controllers',
                onTap: () {},
              ),
              _buildSubItem(
                Icons.hub_outlined,
                'Endpoints',
                onTap: () {},
              ),
              _buildSubItem(
                Icons.dns_outlined,
                'Endpoints',
                onTap: () {},
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
    return Container(
      // margin: const EdgeInsets.only(bottom: 2),
      //if selected is true change background color to light blue
      color: isSelected ? Colors.blue[100] : Colors.transparent,
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
    );
  }
}
