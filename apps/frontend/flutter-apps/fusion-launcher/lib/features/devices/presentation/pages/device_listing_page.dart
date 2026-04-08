import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/alerts/alerts_dashboard.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/live_device_widgets.dart';
import 'package:fusion_launcher/features/projects/models/device_system_info.dart';
import 'package:fusion_launcher/features/projects/view_model/meter_data/meter_data_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

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
  @override
  void initState() {
    super.initState();
    serviceLocator<MeterDataViewModel>().registerObserver();
  }

  @override
  void dispose() {
    serviceLocator<MeterDataViewModel>().unregisterObserver();
    super.dispose();
  }

  List<HardwareComponent> get _fusionDevices {
    final List<HardwareComponent> dsp = serviceLocator<ProjectViewModel>().fusionDsps;
    final List<HardwareComponent> amplifiers = serviceLocator<ProjectViewModel>().amplifiers;
    final List<HardwareComponent> controllers = serviceLocator<ProjectViewModel>().fusionControllers;
    final List<HardwareComponent> endpoints = serviceLocator<ProjectViewModel>().fusionEndpoints;
    return <HardwareComponent>[...dsp, ...amplifiers, ...controllers, ...endpoints];
  }

  String _getDeviceLocation(HardwareComponent device) {
    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>().getZonesForListeningArea(
        areaId: device.locationEntity.listeningAreaId!,
      );
      if (zone != null) return zone.name;
      final SubZone? subZone = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(
        areaId: device.locationEntity.listeningAreaId!,
      );
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>().getZoneForSubZone(subZoneId: subZone.id);
        if (parentZone != null) return "${parentZone.name} > ${subZone.name}";
        return subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id);
    if (location != null) return location.name;
    return "--";
  }

  @override
  Widget build(BuildContext context) {
    final List<HardwareComponent> devices = _fusionDevices;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
        FusionTableColumn(key: 'location', header: 'LOCATION', flex: 3),
        FusionTableColumn(key: 'ip', header: 'IP', flex: 2),
        FusionTableColumn(key: 'firmware', header: 'F.W.', flex: 1),
        FusionTableColumn(key: 'temp', header: 'TEMP', flex: 1),
        FusionTableColumn(key: 'disk', header: 'DISK USE', flex: 1),
        FusionTableColumn(key: 'cpu', header: 'CPU USE', flex: 1),
        FusionTableColumn(key: 'controls', header: 'CONTROLS', flex: 2, sortable: false),
      ],
      rows:
          devices.asMap().entries.map((MapEntry<int, HardwareComponent> entry) {
            return _buildFusionRow(entry.value, entry.key);
          }).toList(),
    );
  }

  FusionTableRow _buildFusionRow(HardwareComponent device, int index) {
    final String deviceName = device.name;
    final String locationName = _getDeviceLocation(device);
    final bool showTempDisk = device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp");
    final bool showCpu = device is FusionDsp || (device is Amplifier && device.hardwareName.startsWith("PSM"));

    return FusionTableRow(
      key: device.id,
      cells: <String, FusionTableCell>{
        'status': FusionTableCell(
          value: 0,
          child: LiveStatusDot(
            deviceId: device.id,
            size: 10,
            onlineColor: const Color(0xFF4CAF50),
            offlineColor: const Color(0xFF9E9E9E),
          ),
        ),
        'deviceName': FusionTableCell(
          value: deviceName,
          child: _buildLinkText(device),
        ),
        'location': FusionTableCell(
          value: locationName,
          child: FusionAppText(text: locationName, style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'ip': FusionTableCell(
          value: '--',
          child: FusionAppText(text: '--', style: context.textTheme.labelMedium, maxLine: 1),
        ),
        'firmware': FusionTableCell(
          value: '--',
          child: Text("--", style: TextStyle(color: context.colorScheme.primaryWhite)),
        ),
        'temp': FusionTableCell(
          value: 0,
          child:
              showTempDisk
                  ? LiveDeviceMetric(
                    deviceId: device.id,
                    builder: (DeviceSystemInfo? info, bool online) {
                      if (!online) return buildDash(color: context.colorScheme.primaryWhite);
                      return CompactThermostatWidget(temperature: info?.temperature.round() ?? 0, maxTemperature: 100);
                    },
                  )
                  : buildDash(color: context.colorScheme.primaryWhite),
        ),
        'disk': FusionTableCell(
          value: 0,
          child:
              showTempDisk
                  ? LiveDeviceMetric(
                    deviceId: device.id,
                    builder: (DeviceSystemInfo? info, bool online) {
                      if (!online) return buildDash(color: context.colorScheme.primaryWhite);
                      final double disk = info?.emmc ?? 0;
                      return Row(
                        children: <Widget>[
                          GaugeWidget(value: disk, size: const Size(24, 24)),
                          const SizedBox(width: 6),
                          FusionAppText(text: "${disk.toInt()}%", style: context.textTheme.labelMedium),
                        ],
                      );
                    },
                  )
                  : buildDash(color: context.colorScheme.primaryWhite),
        ),
        'cpu': FusionTableCell(
          value: 0,
          child:
              showCpu
                  ? LiveDeviceMetric(
                    deviceId: device.id,
                    builder: (DeviceSystemInfo? info, bool online) {
                      if (!online) return buildDash(color: context.colorScheme.primaryWhite);
                      final double cpu = info?.ram ?? 0;
                      return Row(
                        children: <Widget>[
                          DiskUsageWidget(value: cpu, size: const Size(24, 24)),
                          const SizedBox(width: 6),
                          FusionAppText(text: "${cpu.toInt()}%", style: context.textTheme.labelMedium),
                        ],
                      );
                    },
                  )
                  : buildDash(color: context.colorScheme.primaryWhite),
        ),
        'controls': FusionTableCell(
          value: '',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (device is! FusionDsp && (device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp"))) ...<Widget>[
                FusionNeumorphicButton(
                  semanticId: 'standby_button',
                  width: 26,
                  height: 26,
                  borderRadius: 6,
                  onTap: () => _showStandbyConfirmation(context, device),
                  child: FusionImage.asset(AssetIcons.standbyIcon, height: 12, width: 12, assetColor: context.colorScheme.iconWhite),
                ),
                const SizedBox(width: 10),
              ],
              if (device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp"))
                FusionNeumorphicButton(
                  semanticId: 'reboot_button',
                  width: 26,
                  height: 26,
                  borderRadius: 6,
                  onTap: () => _showRebootConfirmation(context, device),
                  child: FusionImage.asset(AssetIcons.rebootIcon, height: 12, width: 12, assetColor: context.colorScheme.iconWhite),
                ),
            ],
          ),
        ),
      },
    );
  }

  Widget _buildLinkText(HardwareComponent device) {
    return InkWell(
      onTap: () {
        if (device is! Amplifier || !device.hardwareName.toLowerCase().startsWith("pp")) {
          Navigator.pushNamed(context, Routes.deviceDetails, arguments: device.id);
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

  void _showStandbyConfirmation(BuildContext context, HardwareComponent device) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => FusionActionPopup(
            title: 'STANDBY',
            description: 'Do you want to set ${device.name} device to standby ?',
            loadingMessage: 'Device going standby',
            onConfirm: () {},
          ),
    );
    if (result == true && context.mounted) {
      FusionToast.success(context, message: "${device.name} set to standby successful.");
    }
  }

  _showRebootConfirmation(BuildContext context, HardwareComponent device) async {
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
      FusionToast.success(context, message: "${device.name} reboot successful.");
    }
  }
}
