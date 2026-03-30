import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/status_indicator.dart';

class DeviceOverviewTab extends StatelessWidget {
  final Device device;

  const DeviceOverviewTab({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// TOP ROW
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// DEVICE IDENTITY
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _cardTitle("Device Identity"),
                      const SizedBox(height: 20),

                      _detail("Name", device.name),
                      const SizedBox(height: 16),

                      _detail("Model Name", device.model),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _detail(
                              "Serial Number",
                              device.serialNumber,
                            ),
                          ),
                          Expanded(
                            child: _detail("Device ID", device.deviceId),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _detail("Last Seen", device.lastSeen),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              /// TELEMETRY
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
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FusionAppText(
                              text: "Online",
                              style: GoogleFonts.montserrat(
                                // color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _telemetryRow("Temperature", "${device.temperature}°C"),

                      const SizedBox(height: 16),

                      _telemetryRow("CPU Usage", "${device.cpuUsage}"),

                      const SizedBox(height: 16),

                      _telemetryRow("RAM Usage", "${device.memoryUsage}"),

                      const SizedBox(height: 16),

                      _telemetryRow(
                        "Device Health State",
                        StatusIndicator(status: device.status),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              /// LOCATION
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle("Location"),
                      const SizedBox(height: 20),

                      _detail("Project", device.project),
                      const SizedBox(height: 16),

                      _detail("Region", "North America"),
                      const SizedBox(height: 16),

                      _detail("Location", device.location),
                      const SizedBox(height: 16),

                      _detail("Assigned Zone", device.zone),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// CARD
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  /// CARD TITLE
  Widget _cardTitle(String text) {
    return FusionAppText(
      text: text,
      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  /// DETAIL
  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FusionAppText(
          text: label,
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        FusionAppText(
          text: value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// TELEMETRY ROW
  Widget _telemetryRow(String label, dynamic value) {
    return Row(
      children: [
        Expanded(
          child: FusionAppText(
            text: label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              // color: Colors.grey[700],
            ),
          ),
        ),
        value is Widget
            ? value
            : FusionAppText(
                text: value.toString(),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  /// ACTION BUTTON
  Widget _actionButton({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          FusionAppText(
            text: text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
