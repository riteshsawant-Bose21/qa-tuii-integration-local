import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required Color backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: context.colorScheme.elevation3,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colorScheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: FusionAppText(text: e, style: GoogleFonts.montserrat()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
