import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_page_widgets/stat_card.dart';

class DevicesOverview extends StatelessWidget {
  final int total;
  final int healthy;
  final int critical;
  final int inactive;

  const DevicesOverview({
    super.key,
    required this.total,
    required this.healthy,
    required this.critical,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [

        SizedBox(
          width: 220,
          child: StatCard(
            title: "Total Devices",
            value: total.toString(),
            icon: Icons.devices,
            color: Colors.black,
          ),
        ),

        SizedBox(
          width: 220,
          child: StatCard(
            title: "Healthy",
            value: healthy.toString(),
            subtitle: "${((healthy / total) * 100).toStringAsFixed(1)}%",
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),

        SizedBox(
          width: 220,
          child: StatCard(
            title: "Critical",
            value: critical.toString(),
            subtitle: "${((critical / total) * 100).toStringAsFixed(1)}%",
            icon: Icons.cancel,
            color: Colors.red,
          ),
        ),

        SizedBox(
          width: 220,
          child: StatCard(
            title: "Inactive",
            value: inactive.toString(),
            subtitle: "${((inactive / total) * 100).toStringAsFixed(1)}%",
            icon: Icons.pause_circle,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}