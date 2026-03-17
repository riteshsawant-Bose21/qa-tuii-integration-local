import 'package:flutter/material.dart';
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
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// BACK BUTTON
            TextButton.icon(
              onPressed: () => context.go(AppConstants.devicesRoute),
              icon: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
              label: Text(
                "Back to Devices",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.grey[200];
                  }
                  return Colors.transparent;
                }),
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
                      Text(
                        widget.device.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
              DeviceIncidentsTab(incidents: widget.device.incidents,),

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
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabButton("Overview", DeviceDetailTab.overview),
          _tabButton("Incidents", DeviceDetailTab.incidents),
          _tabButton("Activity", DeviceDetailTab.activity),
          _tabButton("Telemetry", DeviceDetailTab.telemetry),
        ],
      ),
    );
  }

  Widget _tabButton(String text, DeviceDetailTab tab) {
    final selected = _selectedTab == tab;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

