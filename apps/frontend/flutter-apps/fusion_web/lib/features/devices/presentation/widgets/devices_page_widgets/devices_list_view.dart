import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/handlers/devices_action_handler.dart';
import '../../../data/models/devices_model.dart';
import 'device_row.dart';
import 'device_table_header.dart';

class DevicesListView extends StatelessWidget {
  final List<Device> devices;
  final Function(Device) onDeviceTap;

  const DevicesListView({super.key, required this.devices,required this.onDeviceTap,});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.white,
      ),
      child: Column(
        children: [
          const DeviceTableHeader(),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
             itemBuilder: (context, index) {
              final device = devices[index]; 

              return DeviceRow(
                device: device,
                isLast: index == devices.length - 1,
                onTap: onDeviceTap, 
              );
            },
          ),
        ],
      ),
    );
  }
}
