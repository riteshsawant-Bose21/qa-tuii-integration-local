import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/status_indicator.dart';

class DeviceOverviewTab extends StatelessWidget {
  final Device device;

  const DeviceOverviewTab({
    super.key,
    required this.device,
  });

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
                            child: _detail(
                              "Device ID",
                              device.deviceId,
                            ),
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Online",
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _telemetryRow(
                        "Temperature",
                        "${device.temperature}°C",
                      ),

                      const SizedBox(height: 16),

                      _telemetryRow(
                        "CPU Usage",
                        "${device.cpuUsage}",
                      ),

                      const SizedBox(height: 16),

                      _telemetryRow(
                        "RAM Usage",
                        "${device.memoryUsage}",
                      ),

                      const SizedBox(height: 16),

                      _telemetryRow(
                        "Device Health State",
                        StatusIndicator(status: device.status),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        /// SECOND ROW
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

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

              const SizedBox(width: 24),

              /// ACTIONS
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle("Device Actions"),
                      const SizedBox(height: 20),

                      _actionButton(
                        icon: Icons.restart_alt,
                        text: "Reboot Device",
                      ),

                      const SizedBox(height: 12),

                      _actionButton(
                        icon: Icons.power_settings_new,
                        text: "Enter Standby Mode",
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "Actions may cause temporary service interruption",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CARD
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: child,
    );
  }

  /// CARD TITLE
  Widget _cardTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// DETAIL
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

  /// TELEMETRY ROW
  Widget _telemetryRow(String label, dynamic value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        value is Widget
            ? value
            : Text(
                value.toString(),
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
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
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