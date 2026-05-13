import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/status_indicator.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_detail_page_widgets/device_activity_tab.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_detail_page_widgets/device_incidents_tab.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_detail_page_widgets/device_overview_tab.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_detail_page_widgets/device_telemetry_tab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';

enum DeviceDetailTab { overview, incidents, activity, telemetry }

class DeviceDetailPage extends StatefulWidget {
  final Device device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  DeviceDetailTab _selectedTab = DeviceDetailTab.overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// BACK BUTTON
            TextButton.icon(
              onPressed: () {
                // context.pushReplacement(AppConstants.devicesRoute);
                context.pop();
              },
              icon: Icon(
                Icons.arrow_back,
                size: 18,
                color: context.colorScheme.elevation6,
              ),
              label: FusionAppText(
                text: "Back to Devices",
                // style: GoogleFonts.montserrat(
                //   fontSize: 14,
                //   fontWeight: FontWeight.w500,
                //   color: Colors.black,
                // ),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return context.colorScheme.elevation2; // hover background
                  }
                  return Colors.transparent;
                }),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FusionAppText(
                        text: widget.device.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FusionAppText(
                        text:
                            "Serial: ${widget.device.serialNumber}  •  ID: ${widget.device.deviceId}",
                        style: GoogleFonts.montserrat(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                StatusIndicator(status: widget.device.status),
              ],
            ),

            const SizedBox(height: 28),

            /// TOP SUMMARY CARDS
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _statCard(
                      "Model",
                      widget.device.model,
                      widget.device.deviceType,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _statCard(
                      "Firmware Version",
                      widget.device.firmware,
                      "Up to date",
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _statCard(
                      "Last Seen",
                      widget.device.lastSeen,
                      "${widget.device.online}",
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _statCard(
                      "Open Incidents",
                      "${widget.device.incidents}",
                      "${widget.device.incidents} total",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// TABS
            _tabs(),

            const SizedBox(height: 24),

            if (_selectedTab == DeviceDetailTab.overview)
              DeviceOverviewTab(device: widget.device),

            if (_selectedTab == DeviceDetailTab.incidents)
              DeviceIncidentsTab(incidents: widget.device.incidents),

            if (_selectedTab == DeviceDetailTab.activity)
              const DeviceActivityTab(),

            if (_selectedTab == DeviceDetailTab.telemetry)
              const DeviceTelemetryTab(),
          ],
        ),
      ),
    );
  }

  /// TABS CONTAINER
  Widget _tabs() {
    return Row(
      children: [
        _tabButton("Overview", DeviceDetailTab.overview),
        const SizedBox(width: 8),
        _tabButton("Incidents", DeviceDetailTab.incidents),
        const SizedBox(width: 8),
        _tabButton("Activity", DeviceDetailTab.activity),
        const SizedBox(width: 8),
        _tabButton("Telemetry", DeviceDetailTab.telemetry),
      ],
    );
  }

  Widget _tabButton(String text, DeviceDetailTab tab) {
    final selected = _selectedTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.elevation2 : Colors.transparent,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: selected
                ? context.colorScheme.elevation4
                : context.colorScheme.elevation3,
          ),
        ),
        child: FusionAppText(text: text),
      ),
    );
  }

  Widget _statCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // color: Colors.white,
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FusionAppText(
            text: title,
            // style: GoogleFonts.montserrat(
            //   fontSize: 13,
            //   color: Colors.grey[600],
            // ),
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: value,
            // style: GoogleFonts.montserrat(
            //   fontSize: 20,
            //   fontWeight: FontWeight.w700,
            // ),
          ),
          const SizedBox(height: 4),
          FusionAppText(
            text: subtitle,
            // style: GoogleFonts.montserrat(
            //   fontSize: 12,
            //   color: Colors.grey[500],
            // ),
          ),
        ],
      ),
    );
  }
}
