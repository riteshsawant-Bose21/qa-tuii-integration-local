import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'health_stat.dart';

class DeviceHealthBox extends StatelessWidget {
  final int healthy;
  final int warning;
  final int critical;

  const DeviceHealthBox({
    super.key,
    required this.healthy,
    required this.warning,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Health',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HealthStat(
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF22C55E),
                count: healthy,
              ),
              const SizedBox(width: 16),
              HealthStat(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFF59E0B),
                count: warning,
              ),
              const SizedBox(width: 16),
              HealthStat(
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
                count: critical,
              ),
            ],
          ),
        ],
      ),
    );
  }
}