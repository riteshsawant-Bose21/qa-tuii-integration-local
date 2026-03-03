import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'device_details_footer.dart';
import 'device_info_card.dart';

class DeviceLeftSideBar extends StatelessWidget {
  final HardwareComponent device;

  const DeviceLeftSideBar({
    super.key,
    required this.device,
  });

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
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.elevation2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Header with Back Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              children: <Widget>[
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 14,
                    color: context.colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                FusionAppText(
                  text: "DEVICE DETAILS",
                  style: context.textTheme.labelSmall!.copyWith(
                    color: context.colorScheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(
              color: context.colorScheme.elevation2,
              thickness: 1,
            ),
          ),

          // 2. Device Identity
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FusionAppText(
                              text: device.name,
                              style: context.textTheme.labelLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FusionAppText(
                              text: device.hardwareName,
                              style: context.textTheme.labelSmall!.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: context.colorScheme.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Connectivity Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: <Widget>[
                        FusionNeumorphicButton(
                          semanticId: 'left_side_bar_bluetooth_button',
                          borderRadius: 4,
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation1,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.bluetooth,
                              size: 14,
                              color: context.colorScheme.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FusionNeumorphicButton(
                          semanticId: 'left_side_bar_wifi_button',
                          borderRadius: 4,
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation1,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.wifi,
                              size: 14,
                              color: context.colorScheme.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Device Image
                  Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryWhite,
                      // Placeholder pattern or image asset
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: FusionImage.asset(
                      device.assetImagePath,

                      height: 64,
                      fit: BoxFit.contain,
                    ), // Placeholder
                  ),

                  // 5. Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: <Widget>[
                        // Location
                        DeviceInfoCard(
                          label: "Equipment Location",
                          value: _getDeviceLocation(device),
                          assetPath: AssetIcons.eqLocation,
                        ),
                        const SizedBox(height: 8),
                        // Temp
                        const DeviceInfoCard(
                          label: "Temperature / Moderate",
                          value: "35°C",
                          assetPath: AssetIcons.temperature,
                        ),
                        const SizedBox(height: 8),
                        // CPU / Disk Row
                        const Row(
                          children: <Widget>[
                            Expanded(
                              child: DeviceInfoCard(
                                label: "CPU Usage",
                                value: "63%",
                                assetPath: AssetIcons.levelIndicator,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: DeviceInfoCard(
                                label: "Disk Usage",
                                value: "63%",
                                assetPath: AssetIcons.diskUsage,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 6. Reboot Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FusionNeumorphicButton(
                      semanticId: 'left_side_bar_reboot_button',
                      text: "Reboot Device",
                      onTap: () {},
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 8,
                      color: context.colorScheme.elevation1,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // 7. Footer Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Divider(
                          height: 32,
                          thickness: 1,
                          color: context.colorScheme.elevation2,
                        ),

                        DeviceDetailsFooter(
                          label: "Model",
                          value: device.hardwareName,
                        ),
                        const SizedBox(height: 8),
                        DeviceDetailsFooter(
                          label: "Firmware Version",
                          value: "v1.0.1 ",
                          info: Row(
                            children: <Widget>[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.green,
                                  shape: BoxShape.circle,
                                ),
                              ),

                              const SizedBox(width: 4),
                              FusionAppText(
                                text: "Up to Date",
                                style: context.textTheme.labelSmall!.copyWith(
                                  color: context.colorScheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const DeviceDetailsFooter(
                          label: "Serial Number",
                          value: "DG221G28983",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
