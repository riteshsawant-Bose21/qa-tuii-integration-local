import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;

  const HealthStat({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}