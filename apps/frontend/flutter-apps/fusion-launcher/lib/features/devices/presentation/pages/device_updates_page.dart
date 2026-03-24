import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/alerts/alerts_dashboard.dart';
import 'package:fusion_lib/fusion_lib.dart';

// Assuming these exist in your project structure based on imports provided
import '../../../../core/router/routes.dart';
import '../widgets/device/firmware_update_flow.dart';

// --- THE MAIN TAB WIDGET ---

class DeviceUpdatesTab extends StatefulWidget {
  const DeviceUpdatesTab({super.key});

  @override
  State<DeviceUpdatesTab> createState() => _DeviceUpdatesTabState();
}

class _DeviceUpdatesTabState extends State<DeviceUpdatesTab> {
  // Access Real Devices from Service Locator
  List<HardwareComponent> get _fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    final List<HardwareComponent> endpoints = serviceLocator<ProjectViewModel>().fusionEndpoints;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers, ...endpoints];
  }

  // Location Logic (Ported from DashboardDeviceCard)
  String _getDeviceLocation(HardwareComponent device) {
    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: device.locationEntity.listeningAreaId!);
      if (zone != null) {
        return zone.name;
      }
      final SubZone? subZone = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(areaId: device.locationEntity.listeningAreaId!);
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>().getZoneForSubZone(subZoneId: subZone.id);
        if (parentZone != null) {
          return "${parentZone.name} > ${subZone.name}";
        }
        return subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id);
    if (location != null) {
      return location.name;
    }
    return "--";
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the list for this build
    final List<HardwareComponent> devices = _fusionDevices;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // --- LEFT SIDE: DATA TABLE ---
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colorScheme.elevation2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildDeviceTable(devices),
          ),
        ),

        const SizedBox(width: 4),

        // --- RIGHT SIDE: ALERTS SIDEBAR ---
        const Expanded(
          flex: 1,
          child: AlertsDashboard(),
        ),
      ],
    );
  }

  Widget _buildDeviceTable(List<HardwareComponent> devices) {
    return FusionTable(
      columns: const <FusionTableColumn>[
        FusionTableColumn(key: 'status', header: 'STATUS', flex: 1),
        FusionTableColumn(key: 'deviceName', header: 'DEVICE NAME', flex: 2),
        FusionTableColumn(key: 'model', header: 'MODEL', flex: 2),
        FusionTableColumn(key: 'location', header: 'LOCATION', flex: 3),
        FusionTableColumn(key: 'ip', header: 'IP', flex: 2),
        FusionTableColumn(key: 'firmware', header: 'F.W.', flex: 1),
        FusionTableColumn(key: 'updates', header: 'UPDATE STATUS', flex: 3, sortable: false),
      ],
      // Map real devices to rows, passing index for dummy data generation
      rows:
          devices.asMap().entries.map((MapEntry<int, HardwareComponent> entry) {
            return _buildFusionRow(entry.value, entry.key);
          }).toList(),
    );
  }

  FusionTableRow _buildFusionRow(HardwareComponent device, int index) {
    // --- DUMMY DATA GENERATION ---
    final Random r = Random(index); // Seed with index to keep values stable during rebuilds
    final bool isOnline = index % 5 != 4; // Mock status logic
    final String dummyIp = "192.168.50.${100 + index}";
    final String dummyFirmware = "v${1 + r.nextInt(3)}.${r.nextInt(9)}";

    // --- REAL DATA MAPPING ---
    final String deviceName = device.name;
    final String modelName = device.hardwareName;
    final String locationName = _getDeviceLocation(device);

    return FusionTableRow(
      key: device.id,
      cells: <String, FusionTableCell>{
        'status': FusionTableCell(
          value: isOnline ? 1 : 0,
          child: _buildStatusDot(isOnline),
        ),
        'deviceName': FusionTableCell(
          value: deviceName,
          child: _buildLinkText(
            device: device,
          ),
        ),
        'model': FusionTableCell(
          value: modelName,
          child: FusionAppText(text: modelName, style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'location': FusionTableCell(
          value: locationName,
          child: FusionAppText(text: locationName, style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'ip': FusionTableCell(
          value: dummyIp,
          child: FusionAppText(text: dummyIp, style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'firmware': FusionTableCell(
          value: dummyFirmware,
          child: FusionAppText(text: dummyFirmware, style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'updates': const FusionTableCell(
          value: '',
          child: CompactFirmwareUpdateWidget(),
        ),
      },
    );
  }

  // Helper Widgets

  Widget _buildStatusDot(bool isOnline) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLinkText({
    required HardwareComponent device,
  }) {
    return InkWell(
      onTap: () {
        if (device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp")) {
          Navigator.pushNamed(
            context,
            Routes.deviceDetails,
            arguments: device.id,
          );
        }
      },
      child: FusionAppText(
        text: device.name,
        style: context.textTheme.labelMedium!.copyWith(
          color: context.colorScheme.green,
          decoration: TextDecoration.underline,
          decorationColor: context.colorScheme.green,
          fontSize: 13,
        ),
        maxLine: 1,
        textOverflow: TextOverflow.ellipsis,
      ),
    );
  }
}
