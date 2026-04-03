import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/models/device_system_info.dart';
import 'package:fusion_launcher/features/projects/view_model/meter_data/meter_data_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/router/routes.dart';
import '../../../../devices/presentation/widgets/themostat_painter.dart';
import 'disk_usage_widget.dart';
import 'guage_widget.dart';

class DashboardDeviceCard extends StatefulWidget {
  final HardwareComponent device;
  final int index;

  const DashboardDeviceCard({
    super.key,
    required this.device,
    required this.index,
  });

  @override
  State<DashboardDeviceCard> createState() => _DashboardDeviceCardState();
}

class _DashboardDeviceCardState extends State<DashboardDeviceCard> {
  bool _isPlayingAnimation = false;
  String _loadingTitle = '';
  String _loadingMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    serviceLocator<MeterDataViewModel>().registerObserver();
  }

  @override
  void dispose() {
    _timer?.cancel();
    serviceLocator<MeterDataViewModel>().unregisterObserver();
    super.dispose();
  }

  String get location {
    if (widget.device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>().getZonesForListeningArea(
        areaId: widget.device.locationEntity.listeningAreaId!,
      );
      if (zone != null) {
        return zone.name;
      }
      final SubZone? subZone = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(
        areaId: widget.device.locationEntity.listeningAreaId!,
      );
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>().getZoneForSubZone(subZoneId: subZone.id);
        if (parentZone != null) {
          return "${parentZone.name} > ${subZone.name}";
        }
        return subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: widget.device.id);
    if (location != null) {
      return location.name;
    }
    return "--";
  }

  /// Whether the device is online — determined by whether we have received
  /// live system-monitor telemetry for this device.
  bool _isDeviceOnline(MeterDataState meterState) {
    final DeviceSystemInfo? info = meterState.systemInfoFor(widget.device.id);
    return meterState.isConnected && info != null && info.hasData;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeterDataViewModel, MeterDataState>(
      bloc: serviceLocator<MeterDataViewModel>(),
      builder: (BuildContext context, MeterDataState meterState) {
        final bool isOnline = _isDeviceOnline(meterState);
        final DeviceSystemInfo? sysInfo = meterState.systemInfoFor(widget.device.id);

        final double temperature = sysInfo?.temperature ?? 0;
        final double diskUsage = sysInfo?.emmc ?? 0;
        final double cpuUsage = sysInfo?.ram ?? 0;

        return _buildCard(
          context,
          isOnline: isOnline,
          temperature: temperature.round(),
          diskUsage: diskUsage,
          cpuUsage: cpuUsage,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isOnline,
    required int temperature,
    required double diskUsage,
    required double cpuUsage,
  }) {
    return InkWell(
      onTap: () {
        if (!_isPlayingAnimation) {
          if (widget.device is! Amplifier || !widget.device.hardwareName.toLowerCase().startsWith("pp")) {
            Navigator.pushNamed(
              context,
              Routes.deviceDetails,
              arguments: widget.device.id,
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colorScheme.elevation3,
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    // PADDING: 12.0 horizontal (Matches Header's effective padding)
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: <Widget>[
                        // 1. Device Info (FLEX 5 - MATCHES HEADER)
                        Expanded(
                          flex: 6,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 50,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primaryWhite,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    // Placeholder for device icon - In real implementation, this would be an actual image/icon based on device type
                                    Center(
                                      child: FusionImage.asset(
                                        widget.device.assetImagePath,
                                      ),
                                    ),

                                    Positioned(
                                      left: 4,
                                      top: 4,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isOnline ? context.colorScheme.green : context.colorScheme.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: widget.device.name,
                                      style: context.textTheme.labelMedium,
                                      textOverflow: TextOverflow.ellipsis,
                                      maxLine: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: <Widget>[
                                        Flexible(
                                          child: FusionAppText(
                                            text: widget.device.hardwareName,
                                            style: context.textTheme.labelSmall!.copyWith(
                                              color: context.colorScheme.textPrimary,
                                              fontSize: 11,
                                            ),
                                            textOverflow: TextOverflow.ellipsis,
                                            maxLine: 1,
                                          ),
                                        ),
                                        //small separator dot
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.textSecondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: FusionAppText(
                                            text: location,
                                            style: context.textTheme.labelSmall!.copyWith(
                                              color: context.colorScheme.textPrimary,
                                              fontSize: 11,
                                            ),
                                            textOverflow: TextOverflow.ellipsis,
                                            maxLine: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_isPlayingAnimation) ...<Widget>[
                          Expanded(
                            flex: 6,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: _loadingTitle,
                                        style: context.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FusionAppText(
                                        text: _loadingMessage,
                                        style: context.textTheme.labelSmall?.copyWith(
                                          color: context.colorScheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ] else ...<Widget>[
                          // 2. Metrics (FLEX 2 EACH - MATCHES HEADER)
                          Expanded(
                            flex: 2,
                            child:
                                (isOnline && (widget.device is! Amplifier || !widget.device.hardwareName.toLowerCase().startsWith("pp")))
                                    ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: CompactThermostatWidget(
                                        temperature: temperature,
                                        maxTemperature: 100,
                                      ),
                                    )
                                    : _buildDash(),
                          ),

                          Expanded(
                            flex: 2,
                            child:
                                (isOnline && (widget.device is! Amplifier || !widget.device.hardwareName.toLowerCase().startsWith("pp")))
                                    ? Row(
                                      children: <Widget>[
                                        GaugeWidget(
                                          value: diskUsage,
                                          size: const Size(24, 24),
                                        ),
                                        const SizedBox(width: 6),
                                        FusionAppText(
                                          text: "${diskUsage.toInt()}%",
                                          style: context.textTheme.labelMedium,
                                        ),
                                      ],
                                    )
                                    : _buildDash(),
                          ),

                          Expanded(
                            flex: 2,
                            child:
                                (isOnline && (widget.device is FusionDsp || (widget.device is Amplifier && widget.device.hardwareName.startsWith("PSM"))))
                                    ? Row(
                                      children: <Widget>[
                                        DiskUsageWidget(
                                          value: cpuUsage,
                                          size: const Size(24, 24),
                                        ),
                                        const SizedBox(width: 6),
                                        FusionAppText(
                                          text: "${cpuUsage.toInt()}%",
                                          style: context.textTheme.labelMedium,
                                        ),
                                      ],
                                    )
                                    : _buildDash(),
                          ),

                          // 3. Controls (FLEX 2 - MATCHES HEADER)
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                if (widget.device is! FusionDsp &&
                                    (widget.device is! Amplifier || !widget.device.hardwareName.toLowerCase().startsWith("pp"))) ...<Widget>[
                                  FusionNeumorphicButton(
                                    semanticId: 'standby_button',
                                    width: 26,
                                    height: 26,
                                    borderRadius: 6,
                                    color: context.colorScheme.elevation2,
                                    enabled: false,
                                    onTap: () {
                                      _showStandbyConfirmation(context);
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

                                if (widget.device is! Amplifier || !widget.device.hardwareName.toLowerCase().startsWith("pp"))
                                  FusionNeumorphicButton(
                                    semanticId: 'restart_button',
                                    width: 26,
                                    height: 26,
                                    borderRadius: 6,
                                    enabled: false,
                                    color: context.colorScheme.elevation2,
                                    onTap: () {
                                      _showRestartConfirmation(context);
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
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Alert Banner — will be integrated when alert system is implemented.
          ],
        ),
      ),
    );
  }

  void _showStandbyConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => FusionConfirmationPopup(
            title: 'STANDBY',
            description: 'Do you want to set ${widget.device.name} device to standby ?',
            onConfirm: () {
              // TODO: Implement actual standby logic
              _startLoadingState('Please wait...', 'Device going standby');
            },
          ),
    );
  }

  void _showRestartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => FusionConfirmationPopup(
            title: 'RESTART',
            description: 'Do you want to restart ${widget.device.name} device?',
            onConfirm: () {
              // TODO: Implement actual restart logic
              _startLoadingState('Please wait...', 'Device restarting');
            },
          ),
    );
  }

  void _startLoadingState(String title, String message) {
    setState(() {
      _isPlayingAnimation = true;
      _loadingTitle = title;
      _loadingMessage = message;
    });

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPlayingAnimation = false;
        });
      }
    });
  }
}

Widget _buildDash() => const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "-",
    style: TextStyle(
      color: Colors.grey,
    ),
  ),
);
