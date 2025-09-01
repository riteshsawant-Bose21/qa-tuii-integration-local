import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/utils/broadcast_controllers.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/fusion_device/fusion_device.dart';
import 'package:fusion_lib/models/response_callback.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/utils/fusion_utils.dart';
import 'claim_device_popup.dart';
import 'device_assign_button.dart';

class DSPDeviceCard extends StatefulWidget {
  final FusionDevice device;
  final String? vipAddress;
  final Function() onConfigureVip;
  final List<FusionDevice> allDevicesInProject;
  final bool isControlMode;

  const DSPDeviceCard({
    super.key,
    required this.device,
    this.vipAddress,
    required this.onConfigureVip,
    required this.allDevicesInProject,
    required this.isControlMode,
  });

  @override
  State<DSPDeviceCard> createState() => _DSPDeviceCardState();
}

class _DSPDeviceCardState extends State<DSPDeviceCard> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showClearDeviceMappingDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Clear Device Mapping'),
            ],
          ),
          content: const Text(
            'Are you sure you want to clear the device mapping? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetDeviceStatus();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetDeviceStatus() async {
    if (!mounted) return;

    FusionUtils.showLoader(context);

    try {
      final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().patch(
        api: FusionApiEndpoint.fusionDevice,
        additionalPath: widget.device.id,
        data: <String, dynamic>{
          'id': const Uuid().v4(),
          'name': "Fusion ${DateTime.now().microsecond}",
          'location': "",
        },
      );

      if (mounted) {
        FusionUtils.hideLoader(context);

        if (responseCallback.success) {
          //Todo: update this as per new project manager
          // serviceLocator<ProjectViewModel>().updateFusionDevice(
          //   widget.device.copyWith(status: FusionDeviceSetupStatus.notStarted),
          // );
          serviceLocator<ProjectViewModel>().saveProjectToLocal();

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Device mapping cleared successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          debugPrint("Failed to clear device mapping: ${responseCallback.message}");

          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear device mapping: ${responseCallback.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        FusionUtils.hideLoader(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _onClaimDevice() {
    if (widget.device.cloudId == null || widget.device.cloudId!.isEmpty) {
      //show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Device is not registered on cloud.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    QRClaimPopup.show(
      context: context,
      deviceIdToClaim: widget.device.cloudId!,
      deviceName: widget.device.name,
    );
  }

  void _viewDeviceOnCloud() {
    if (widget.device.cloudId == null || widget.device.cloudId!.isEmpty) {
      //show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Device is not registered on cloud.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    print("Navigating to cloud view for device: ${widget.device.name} with ID: ${widget.device.cloudId}");
    //Todo: update this as per new project manager
    // cloudRedirectUrl =
    //     "embed/projects/${serviceLocator<ProjectViewModel>().value.cloudId}?openDeviceDialog=true&deviceId=${widget.device.cloudId!}&token=${serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken)}";
    // Navigate to cloud view
    projectTabBroadcastController.add(cloudTableIndex);
  }

  Widget _buildStatusIndicator() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isSetup = widget.device.status == FusionDeviceSetupStatus.completed;

    return GestureDetector(
      onLongPress: isSetup ? _showClearDeviceMappingDialog : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSetup ? colors.primaryContainer : colors.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSetup ? colors.primary.withOpacity(0.3) : colors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          isSetup ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          color: isSetup ? colors.primary : colors.error,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildDeviceImage() {
    return Container(
      // padding: const EdgeInsets.all(3),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(2),
      //   boxShadow: <BoxShadow>[
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.05),
      //       blurRadius: 4,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: Image.asset(
        "assets/images/bose_pro_dsp.webp",
        height: 32,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _buildMoreActionsMenu() {
    if (!widget.isControlMode) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: "More actions",
      onSelected: (String value) {
        if (value == 'claim') {
          _onClaimDevice();
        } else if (value == 'view') {
          // Navigate to cloud view
          _viewDeviceOnCloud();
        }
      },
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) {
        print("Building popup menu for device: ${widget.device.name} : claimed ${widget.device.isClaimed}");
        return <PopupMenuEntry<String>>[
          if (widget.device.cloudId == null || widget.device.cloudId!.isEmpty)
            const PopupMenuItem<String>(
              value: 'no_claim',
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Device not registered on cloud',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (widget.device.isClaimed)
            PopupMenuItem<String>(
              value: 'view',
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'view device on cloud',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (!widget.device.isClaimed && (widget.device.cloudId != null && widget.device.cloudId!.isNotEmpty))
            PopupMenuItem<String>(
              value: 'claim',
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Claim Device on Cloud',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
    );
  }

  Widget _buildDeviceInfo() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Device name and ID
        Row(
          children: <Widget>[
            _buildStatusIndicator(),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    widget.device.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.device.id,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Network info
        if (widget.device.localIp != null) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                Icons.wifi_rounded,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.device.localIp!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Location info
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Icon(
              Icons.location_on_rounded,
              size: 14,
              color: colors.secondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.device.location,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isSetup = widget.device.status == FusionDeviceSetupStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header row
            Row(
              children: <Widget>[
                Expanded(child: _buildDeviceImage()),
                _buildMoreActionsMenu(),
              ],
            ),

            const SizedBox(height: 16),

            // Device information
            _buildDeviceInfo(),

            // Action button
            if (widget.isControlMode) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AssignDeviceButton(
                  fusionDeviceToMap: widget.device,
                  title: isSetup ? 'Reassign Device' : 'Assign Device',
                  vipAddress: widget.vipAddress,
                  onSetupVip: widget.onConfigureVip,
                  allFusionDevicesInProject: widget.allDevicesInProject,
                  onUnassignDevice: _resetDeviceStatus,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
