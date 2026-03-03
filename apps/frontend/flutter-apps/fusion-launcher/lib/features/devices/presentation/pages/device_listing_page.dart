import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/alerts/alerts_dashboard.dart';
import 'package:fusion_lib/fusion_lib.dart';

// Assuming these exist in your project structure based on imports provided
import '../../../../core/assets/asset_icons.dart';
import '../../../control_dashboard/presentation/widgets/devices/disk_usage_widget.dart';
import '../../../control_dashboard/presentation/widgets/devices/guage_widget.dart';
import '../widgets/themostat_painter.dart';

// --- THE MAIN TAB WIDGET ---

class DeviceListTab extends StatefulWidget {
  const DeviceListTab({super.key});

  @override
  State<DeviceListTab> createState() => _DeviceListTabState();
}

class _DeviceListTabState extends State<DeviceListTab> {
  // Access Real Devices from Service Locator
  List<HardwareComponent> get _fusionDevices {
    // Combine DSPs, Amplifiers, and Controllers
    final List<HardwareComponent> dsp =
        serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers =
        serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers =
        serviceLocator<ProjectViewModel>().fusionControllers;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers];
  }

  String _getDeviceLocation(HardwareComponent device) {
    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>()
          .getZonesForListeningArea(
            areaId: device.locationEntity.listeningAreaId!,
          );
      if (zone != null) {
        return zone.name;
      }
      final SubZone? subZone = serviceLocator<ProjectViewModel>()
          .getSubZoneForListeningArea(
            areaId: device.locationEntity.listeningAreaId!,
          );
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>()
            .getZoneForSubZone(subZoneId: subZone.id);
        if (parentZone != null) {
          return "${parentZone.name} > ${subZone.name}";
        }
        return subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>()
        .getEquipLocationForHardware(hardwareId: device.id);
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

        const SizedBox(width: 24),

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
        // FusionTableColumn(key: 'model', header: 'MODEL', flex: 2),
        FusionTableColumn(key: 'location', header: 'LOCATION', flex: 3),
        FusionTableColumn(key: 'ip', header: 'IP', flex: 2),
        FusionTableColumn(key: 'firmware', header: 'F.W.', flex: 1),
        FusionTableColumn(key: 'temp', header: 'TEMP', flex: 1),
        FusionTableColumn(key: 'disk', header: 'DISK USE', flex: 1),
        FusionTableColumn(key: 'cpu', header: 'CPU USE', flex: 1),
        FusionTableColumn(
          key: 'controls',
          header: 'CONTROLS',
          flex: 2,
          sortable: false,
        ),
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
    final Random r = Random(
      index,
    ); // Seed with index to keep values stable during rebuilds
    final bool isOnline = index % 5 != 4; // Mock status logic
    final int tempCelsius = 20 + r.nextInt(30); // 20-50
    final double diskUsage = 0.2 + (r.nextDouble() * 0.7); // 0.2 - 0.9
    final double cpuUsage = 0.1 + (r.nextDouble() * 0.8); // 0.1 - 0.9
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
          child: _buildLinkText(deviceName, device.id),
        ),
        // 'model': FusionTableCell(
        //   value: modelName,
        //   child: FusionAppText(text: modelName, style: context.textTheme.labelMedium, maxLine: 1),
        // ),
        'location': FusionTableCell(
          value: locationName,
          child: FusionAppText(
            text: locationName,
            style: context.textTheme.labelMedium,
            maxLine: 1,
          ),
        ),
        'ip': FusionTableCell(
          value: dummyIp,
          child: FusionAppText(
            text: dummyIp,
            style: context.textTheme.labelMedium,
            maxLine: 1,
          ),
        ),
        'firmware': FusionTableCell(
          value: dummyFirmware,
          child: FusionAppText(
            text: dummyFirmware,
            style: context.textTheme.labelMedium,
            maxLine: 1,
          ),
        ),
        'temp': FusionTableCell(
          value: tempCelsius,
          child:
              isOnline
                  ? CompactThermostatWidget(
                    temperature: tempCelsius,
                    maxTemperature: 100,
                  )
                  : Text(
                    "-",
                    style: TextStyle(color: context.colorScheme.primaryWhite),
                  ),
        ),
        'disk': FusionTableCell(
          value: diskUsage,
          child:
              isOnline
                  ? Row(
                    children: <Widget>[
                      GaugeWidget(
                        value: 100 * diskUsage,
                        size: const Size(24, 24),
                      ),
                      const SizedBox(width: 6),
                      FusionAppText(
                        text: "${(diskUsage * 100).toInt()}%",
                        style: context.textTheme.labelMedium,
                      ),
                    ],
                  )
                  : Text(
                    "-",
                    style: TextStyle(color: context.colorScheme.primaryWhite),
                  ),
        ),
        'cpu': FusionTableCell(
          value: cpuUsage,
          child:
              isOnline
                  ? Row(
                    children: <Widget>[
                      DiskUsageWidget(
                        value: 100 * cpuUsage,
                        size: const Size(24, 24),
                      ),
                      const SizedBox(width: 6),
                      FusionAppText(
                        text: "${(cpuUsage * 100).toInt()}%",
                        style: context.textTheme.labelMedium,
                      ),
                    ],
                  )
                  : Text(
                    "-",
                    style: TextStyle(color: context.colorScheme.primaryWhite),
                  ),
        ),
        'controls': FusionTableCell(
          value: '',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (device is! FusionDsp) ...<Widget>[
                FusionNeumorphicButton(
                  semanticId: 'device_standby_button',
                  width: 26,
                  height: 26,
                  borderRadius: 6,
                  onTap: () {
                    _showStandbyConfirmation(context, device);
                  },
                  child: FusionImage.asset(
                    AssetIcons.standbyIcon,
                    height: 12,
                    width: 12,
                    assetColor: context.colorScheme.iconWhite,
                  ),
                ),
                const SizedBox(width: 10),
              ],

              FusionNeumorphicButton(
                semanticId: 'device_reboot_button',
                width: 26,
                height: 26,
                borderRadius: 6,
                onTap: () {
                  _showRebootConfirmation(context, device);
                },
                child: FusionImage.asset(
                  AssetIcons.rebootIcon,
                  height: 12,
                  width: 12,
                  assetColor: context.colorScheme.iconWhite,
                ),
              ),
            ],
          ),
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

  Widget _buildLinkText(String deviceName, String deviceId) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.deviceDetails,
          arguments: deviceId,
        );
      },
      child: FusionAppText(
        text: deviceName,
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

  void _showStandbyConfirmation(
    BuildContext context,
    HardwareComponent device,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => FusionActionPopup(
            title: 'STANDBY',
            description:
                'Do you want to set ${device.name} device to standby ?',
            loadingMessage: 'Device going standby',
            onConfirm: () {
              // TODO: Implement actual standby logic if needed before loading
            },
          ),
    );

    if (result == true && context.mounted) {
      FusionToast.success(
        context,
        message: "${device.name} set to standby successful.",
      );
    }
  }

  _showRebootConfirmation(
    BuildContext context,
    HardwareComponent device,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => FusionActionPopup(
            title: 'REBOOT',
            description: 'Do you want to reboot ${device.name} device ?',
            loadingMessage: 'Device rebooting',
            onConfirm: () {},
          ),
    );

    if (result == true && context.mounted) {
      FusionToast.success(
        context,
        message: "${device.name} reboot successful.",
      );
    }
  }
}
