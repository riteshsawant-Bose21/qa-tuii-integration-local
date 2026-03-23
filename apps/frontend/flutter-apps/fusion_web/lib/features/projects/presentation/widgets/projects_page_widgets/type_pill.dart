import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypePill extends StatelessWidget {
  final String type;

  const TypePill({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type.toLowerCase()) {
      case 'installation':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7C3AED);
        break;
      case 'opportunity':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        break;
      case 'poc':
        bg = const Color(0xFFFCE7F3);
        fg = const Color(0xFFBE185D);
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toLowerCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}