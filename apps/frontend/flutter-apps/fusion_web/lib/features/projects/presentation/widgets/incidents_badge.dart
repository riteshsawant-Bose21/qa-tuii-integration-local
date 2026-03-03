import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncidentsBadge extends StatelessWidget {
  final int count;

  const IncidentsBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 incident' : '$count incidents';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFEA580C),
        ),
      ),
    );
  }
}