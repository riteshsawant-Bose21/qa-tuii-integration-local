import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OpenIncidentsWarning extends StatelessWidget {
  final int count;

  const OpenIncidentsWarning({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        count == 1 ? '1 open incident' : '$count open incidents';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEA580C),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }
}