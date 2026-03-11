import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GridInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const GridInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}