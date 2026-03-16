import 'package:flutter/material.dart';
import '../../../data/models/devices_model.dart';
import 'device_row.dart';
import 'device_table_header.dart';

class DevicesListView extends StatelessWidget {
  final List<Device> devices;

  const DevicesListView({super.key, required this.devices});

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
              return DeviceRow(
                device: devices[index],
                isLast: index == devices.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }
}