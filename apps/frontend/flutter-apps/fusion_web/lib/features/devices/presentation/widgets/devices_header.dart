import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DevicesHeader extends StatelessWidget {
  const DevicesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Devices",
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          "Monitor and manage all devices across your ecosystem",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}