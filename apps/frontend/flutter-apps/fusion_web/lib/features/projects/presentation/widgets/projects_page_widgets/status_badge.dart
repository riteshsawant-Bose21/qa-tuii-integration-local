import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();

    Color bg;
    Color fg;
    Color border;

    if (lower == 'commissioned') {
      bg = context.colorScheme.successText.withAlpha(30);
      fg = context.colorScheme.successText;
      border = context.colorScheme.successText;
    } else if (lower == 'proposal') {
      bg = context.colorScheme.volumeYellow.withAlpha(30);
      fg = context.colorScheme.volumeYellow;
      border = context.colorScheme.volumeYellow;
    } else {
      bg = context.colorScheme.infoText.withAlpha(30);
      fg = context.colorScheme.infoText;
      border = context.colorScheme.infoText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: FusionAppText(
        text: lower,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
