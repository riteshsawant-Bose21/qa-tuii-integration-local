import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/widgets/status_indicator.dart';
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
            InkWell(
              onTap: () => context.go(AppConstants.devicesRoute),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Back to Devices",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                StatusIndicator(status: widget.device.status),
              ],
            ),

            const SizedBox(height: 28),

            /// TOP SUMMARY CARDS
            Row(
              children: [
                _statCard("Model", widget.device.model, widget.device.deviceType),
                const SizedBox(width: 16),
                _statCard("Firmware Version", widget.device.firmware, "Up to date"),
                const SizedBox(width: 16),
                _statCard("Last Seen", widget.device.lastSeen, "${widget.device.online}"),
                const SizedBox(width: 16),
                _statCard("Open Incidents", "${widget.device.incidents}", "${widget.device.incidents} total"),
              ],
            ),

            const SizedBox(height: 32),

            /// TABS
            Row(
              children: [
                _tabButton("Overview", DeviceDetailTab.overview),
                const SizedBox(width: 8),
                _tabButton("Incidents", DeviceDetailTab.incidents),
                const SizedBox(width: 8),
                _tabButton("Activity", DeviceDetailTab.activity),
                const SizedBox(width: 8),
                _tabButton("Telemetry", DeviceDetailTab.telemetry),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedTab == DeviceDetailTab.overview)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// DEVICE IDENTITY CARD
                  Expanded(
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Device Identity"),
                          const SizedBox(height: 20),

                          _detail("Name", widget.device.name),
                          const SizedBox(height: 16),
                          _detail("Model Name", widget.device.model),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                  child:
                                      _detail("Serial Number", widget.device.serialNumber)),
                              Expanded(child: _detail("Device ID", widget.device.deviceId)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _detail("Last Seen", widget.device.lastSeen),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  /// TELEMETRY CARD
                  Expanded(
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle("Device Status / Telemetry"),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Icon(Icons.wifi, color: Colors.green),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Online",
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _telemetryRow("Temperature", "${widget.device.temperature}°C"),
                          const SizedBox(height: 16),
                          _telemetryRow("CPU Usage", "${widget.device.cpuUsage}"),
                          const SizedBox(height: 16),
                          _telemetryRow("RAM Usage", "${widget.device.memoryUsage}"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// COMPONENTS

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style:
          GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.thermostat_outlined, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.montserrat(fontSize: 14),
        )
      ],
    );
  }

  Widget _statCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  Widget _tabButton(String text, DeviceDetailTab tab) {
    final selected = _selectedTab == tab;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}