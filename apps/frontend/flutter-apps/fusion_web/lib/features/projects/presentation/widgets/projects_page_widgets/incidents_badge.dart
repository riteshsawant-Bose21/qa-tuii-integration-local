import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';

class IncidentsBadge extends StatelessWidget {
  final int count;

  const IncidentsBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 incident' : '$count incidents';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.errorText),
      ),
      child: FusionAppText(
        text: label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: context.colorScheme.errorText,
        ),
      ),
    );
  }
}
