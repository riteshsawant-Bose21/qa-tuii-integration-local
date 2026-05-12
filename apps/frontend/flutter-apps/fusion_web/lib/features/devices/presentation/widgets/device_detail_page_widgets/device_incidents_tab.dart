
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/devices/presentation/widgets/common_widgets/empty_state_widget.dart';

class DeviceIncidentsTab extends StatelessWidget {
  final int incidents;

  const DeviceIncidentsTab({
    super.key,
    required this.incidents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Incident History",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          /// ZERO INCIDENTS
          if (incidents == 0)
            const EmptyStateWidget(
              title: "No incidents recorded",
              description: "This device has not reported any incidents.",
              icon: Icons.report_problem_outlined,
            )

          /// INCIDENTS PRESENT
          else
            Column(
              children: List.generate(
                incidents,
                (index) => _incidentItem(index + 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _incidentItem(int number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              "Incident #$number",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}