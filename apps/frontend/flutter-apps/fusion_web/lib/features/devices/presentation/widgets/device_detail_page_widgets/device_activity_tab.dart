import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceActivityTab extends StatelessWidget {
  const DeviceActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colorScheme.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FusionAppText(
            text: "Activity Timeline",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 30),

          _timelineItem(
            "Device status changed to healthy",
            "Feb 6, 2026, 02:45 PM",
            context,
          ),

          _timelineItem(
            "Firmware updated to version 2.1.0",
            "Feb 1, 2026, 03:30 PM",
            context,
          ),

          _timelineItem(
            "Device connected to network",
            "Jan 28, 2026, 08:00 PM",
            context,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String title, String time, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.elevation4,
                ),
                child: const Icon(Icons.monitor_heart, size: 18),
              ),
              Container(
                width: 2,
                height: 40,
                color: context.colorScheme.elevation3,
              )
            ],
          ),

          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FusionAppText(
                text: title,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              FusionAppText(
                text: time,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}