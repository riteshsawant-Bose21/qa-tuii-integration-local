import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceTelemetryTab extends StatelessWidget {
  const DeviceTelemetryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// REAL-TIME TELEMETRY
        _card(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("Real-time Telemetry"),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _metricCard("Temperature", "42°C", "Normal", context)),
                  const SizedBox(width: 16),
                  Expanded(child: _metricCard("CPU Usage", "32%", "Avg: 45%", context,)),
                  const SizedBox(width: 16),
                  Expanded(child: _metricCard("Memory", "45%", "512MB / 1GB", context,)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      "Signal Strength",
                      "-42 dBm",
                      "Excellent",
                      context,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _title("Connection Status"),

              const SizedBox(height: 20),

              _detailRow("Network Type", "Ethernet"),
              _detailRow("IP Address", "192.168.1.51"),
              _detailRow("MAC Address", "00:1A:2B:dev-9"),
              _detailRow("Uptime", "47 days, 12 hours"),
            ],
          ),
        ),

        const SizedBox(height: 24),

        /// HISTORICAL TELEMETRY
        _card(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("Historical Telemetry"),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _historyCard("Temperature", "38°C", "56°C", "45°C", context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _historyCard("CPU Usage", "15%", "68%", "42%", context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _historyCard("Memory Usage", "32%", "72%", "52%", context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      "All metrics within normal operating range",
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colorScheme.elevation2,
      ),
      child: child,
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    String subtitle,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color(0xFFE5E5E5)),
        color: context.colorScheme.elevation3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(String title, String min, String max, String avg, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color(0xFFE5E5E5)),
        color: context.colorScheme.elevation3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 14)),
          const SizedBox(height: 10),
          _detailRow("Min", min),
          _detailRow("Max", max),
          _detailRow("Avg", avg),
        ],
      ),
    );
  }
}
