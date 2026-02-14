import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/left_side_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../widgets/details/audio_control_tab.dart';
import '../widgets/details/device_details_tab.dart';
import '../widgets/details/settings_details_tab.dart';

class DeviceDetailsPage extends StatefulWidget {
  final String deviceId;

  const DeviceDetailsPage({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: isController ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  HardwareComponent get device => serviceLocator<ProjectViewModel>().getHardware(hardwareId: widget.deviceId)!;

  bool get isAmplifier => device is Amplifier;

  bool get isController => device is FusionController;

  bool get isDsp => device is FusionDsp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: context.colorScheme.primaryBlack,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- LEFT SIDEBAR (Summary) ---
            SizedBox(
              width: 280, // Fixed width for sidebar
              child: DeviceLeftSideBar(
                device: device,
              ),
            ),

            const SizedBox(width: 16),

            // --- RIGHT CONTENT (Tabs) ---
            Expanded(
              child: Column(
                children: <Widget>[
                  // Custom Tab Bar Row
                  Row(
                    children: <Widget>[
                      if (!isController) ...<Widget>[
                        DeviceDetailsTab(
                          label: "Audio/Control",
                          index: 0,
                          tabController: _tabController,
                        ),
                        const SizedBox(width: 12),
                      ],
                      DeviceDetailsTab(
                        label: "Settings",
                        index: isController ? 0 : 1,
                        tabController: _tabController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe
                      children: <Widget>[
                        if (!isController)
                          AudioControlTab(
                            hardwareComponent: device,
                          ),
                        DeviceSettingsTab(
                          hardwareComponent: device,
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
    );
  }
}
