import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthStat extends StatelessWidget {
  final Widget icon;       
  final int count;
final String semanticId;

   const HealthStat({
    super.key,
    required this.icon,
    required this.count,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        FusionAppText(
              text:
          '$count',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            // fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}