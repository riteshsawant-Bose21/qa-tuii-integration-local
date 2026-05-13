import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
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
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Health',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              // color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HealthStat(
                icon: FusionIcon.icon(Icons.check_circle_outline_rounded, color: context.colorScheme.volumeGreen,),
                count: healthy,
                semanticId: '',
              ),
              const SizedBox(width: 16),
              HealthStat(
                icon: FusionIcon.icon(Icons.warning_amber_rounded, color: context.colorScheme.volumeYellow,),
                count: warning,
                semanticId: '',
              ),
              const SizedBox(width: 16),
              HealthStat(
                icon: FusionIcon.icon(Icons.cancel_outlined, color: context.colorScheme.zone1Dark,),
                count: critical,
                semanticId: '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
