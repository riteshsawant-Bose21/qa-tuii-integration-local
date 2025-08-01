import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/fusion_device.dart';
import 'package:fusion_design_tool_prototype/core/utils/fusion_utils.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/models/response_callback.dart';
import '../../../../../core/network_clients/fusion_network_client.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/services/project_manager.dart';

class AssignDeviceButton extends StatefulWidget {
  final FusionDevice fusionDeviceToMap;
  final String title;
  final String? vipAddress;
  final Function() onSetupVip;
  final List<FusionDevice> allFusionDevicesInProject;
  final Function() onUnassignDevice;

  const AssignDeviceButton({
    super.key,
    required this.fusionDeviceToMap,
    required this.title,
    this.vipAddress,
    required this.onSetupVip,
    required this.allFusionDevicesInProject,
    required this.onUnassignDevice,
  });

  @override
  State<AssignDeviceButton> createState() => _AssignDeviceButtonState();
}

class _AssignDeviceButtonState extends State<AssignDeviceButton> {
  Future<List<FusionDevice>> _fetchDevices() async {
    final ResponseCallback<dynamic> responseCallback =
        await serviceLocator<FusionNetworkClient>().get(
          api: FusionApiEndpoint.fusionDevice,
        );

    if (responseCallback.success && responseCallback.data != null) {
      return (responseCallback.data as List<dynamic>)
          .map((dynamic e) => FusionDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(responseCallback.message);
    }
  }

  void _onMenuItemSelected(FusionDevice selectedDevice) async {
    FusionUtils.showLoader(context);

    print("Selected device: ${selectedDevice.toString()}");

    // final ResponseCallback<dynamic> setVipResponse = await serviceLocator<FusionNetworkClient>().post(
    //   api: FusionApiEndpoint.setVip,
    //   additionalPath: widget.vipAddress,
    //   baseUrlToOverride: "${selectedDevice.localIp!}:8080",
    // );

    final Map<String, dynamic> data = <String, dynamic>{
      'id': widget.fusionDeviceToMap.id,
      'location': widget.fusionDeviceToMap.location,
    };

    if (selectedDevice.name != widget.fusionDeviceToMap.name) {
      data['name'] = widget.fusionDeviceToMap.name;
    }

    final ResponseCallback<dynamic> responseCallback =
        await serviceLocator<FusionNetworkClient>().patch(
          api: FusionApiEndpoint.fusionDevice,
          additionalPath: selectedDevice.id,
          data: data,
        );

    if (mounted) FusionUtils.hideLoader(context);

    if (responseCallback.success) {
      serviceLocator<ProjectManager>().resetFusionDeviceAssignments(
        selectedDevice.id,
      );
      serviceLocator<ProjectManager>().updateFusionDevice(
        widget.fusionDeviceToMap.copyWith(
          status: FusionDeviceSetupStatus.completed,
          localIp: selectedDevice.localIp,
          cloudId: selectedDevice.cloudId,
          isClaimed: selectedDevice.isClaimed
        ),
      );
      serviceLocator<ProjectManager>().saveProject();
      // if (mounted) Navigator.pop(context);
    } else {
      debugPrint("Failed to assign device: ${responseCallback.message}");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AssignDeviceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return PopupMenuButton<FusionDevice>(
      tooltip: 'Show devices',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      color: AppColors.cardSoft,
      itemBuilder: (BuildContext context) {
        if (widget.vipAddress == null || widget.vipAddress!.isEmpty) {
          return <PopupMenuEntry<FusionDevice>>[
            PopupMenuItem<FusionDevice>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'VIP is not configured yet\n Configure VIP to list available devices',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.tertiary, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colors.primary,
                        backgroundColor: colors.primaryContainer,
                        disabledBackgroundColor: colors.primaryContainer,
                        disabledForegroundColor: colors.primary,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSetupVip();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Setup VIP",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        } else {
          return <PopupMenuEntry<FusionDevice>>[
            PopupMenuItem<FusionDevice>(
              enabled: false,
              child: SizedBox(
                width: 300,
                child: FutureBuilder<List<FusionDevice>>(
                  future: _fetchDevices(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<FusionDevice>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading...'),
                        ],
                      );
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.inbox_outlined,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No devices available',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      );
                    } else {
                      final List<MapEntry<int, FusionDevice>> availableDevices =
                          snapshot.data!.asMap().entries.where((
                            MapEntry<int, FusionDevice> entry,
                          ) {
                            final FusionDevice device = entry.value;
                            return device.id != widget.fusionDeviceToMap.id &&
                                !widget.allFusionDevicesInProject.any(
                                  (FusionDevice existingDevice) =>
                                      existingDevice.id == device.id &&
                                      existingDevice.status ==
                                          FusionDeviceSetupStatus.completed,
                                );
                          }).toList();

                      final List<MapEntry<int, FusionDevice>>
                      otherAssignedDevices =
                          snapshot.data!.asMap().entries.where((
                            MapEntry<int, FusionDevice> entry,
                          ) {
                            final FusionDevice device = entry.value;
                            return device.id != widget.fusionDeviceToMap.id &&
                                widget.allFusionDevicesInProject.any(
                                  (FusionDevice existingDevice) =>
                                      existingDevice.id == device.id &&
                                      existingDevice.status ==
                                          FusionDeviceSetupStatus.completed,
                                );
                          }).toList();

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (widget.fusionDeviceToMap.status ==
                                FusionDeviceSetupStatus.completed) ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Currently Mapped Device',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              //load the matching id device from widget.fusionDevicetomap
                              ...snapshot.data!
                                  .asMap()
                                  .entries
                                  .where(
                                    (MapEntry<int, FusionDevice> entry) =>
                                        entry.value.id ==
                                        widget.fusionDeviceToMap.id,
                                  )
                                  .map((MapEntry<int, FusionDevice> entry) {
                                    final int index = entry.key;
                                    final FusionDevice device = entry.value
                                        .copyWith(
                                          status:
                                              FusionDeviceSetupStatus.completed,
                                        );
                                    return buildFusionDeviceCard(
                                      index,
                                      context,
                                      device,
                                      colors,
                                      () {
                                        Navigator.pop(context);
                                        widget.onUnassignDevice();
                                      },
                                      showUnAssign: true,
                                    );
                                  }),
                            ],

                            Row(
                              children: <Widget>[
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Available Devices',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            if (availableDevices.isEmpty) ...<Widget>[
                              // Device count indicator
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    '0 devices',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primarySoft,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...<Widget>[
                              //filter devices, show devices expect widget.fusionDeviceToMap and widget.allFusionDevicesInProject which has status completed
                              ...availableDevices.map((
                                MapEntry<int, FusionDevice> entry,
                              ) {
                                final int index = entry.key;
                                final FusionDevice device = entry.value;
                                return buildFusionDeviceCard(
                                  index,
                                  context,
                                  device,
                                  colors,
                                  () {
                                    Navigator.pop(context);
                                    _onMenuItemSelected(device);

                                  },
                                );
                              }),
                            ],

                            if (otherAssignedDevices.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),

                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Non available Devices',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              //filter devices, show devices expect widget.fusionDeviceToMap and widget.allFusionDevicesInProject which has status completed
                              ...otherAssignedDevices.map((
                                MapEntry<int, FusionDevice> entry,
                              ) {
                                final int index = entry.key;
                                final FusionDevice device = entry.value;
                                return buildFusionDeviceCard(
                                  index,
                                  context,
                                  device,
                                  colors,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Device is already assigned to another fusion instance',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  disable: true,
                                );
                              }),
                            ],

                            // Add some bottom padding for better spacing
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ];
        }
      },
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          disabledBackgroundColor: colors.primaryContainer,
          backgroundColor: colors.primaryContainer,
          disabledForegroundColor: colors.primary,
        ),
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_double_arrow_down_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildFusionDeviceCard(
    int index,
    BuildContext context,
    FusionDevice device,
    ColorScheme colors,
    Function() onTap, {
    bool showUnAssign = false,
    bool disable = false,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primarySoft.withAlpha((0.1 * 255).toInt()),
          highlightColor: AppColors.primarySoft.withAlpha((0.05 * 255).toInt()),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outline.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                // Enhanced device icon with background
                Container(
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/images/bose_dsp.png",
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Device information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),


                        const SizedBox(height: 6),
                        if (device.localIp != null)
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.network_wifi,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                device.localIp!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: colors.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      if (device.location.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: colors.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                device.location,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: colors.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      (showUnAssign)
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // cancel icon
                                const Icon(
                                  Icons.cancel_rounded,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Unassign',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : (disable)
                          ? Container()
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // cancel icon
                                Text(
                                  'Select',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
