import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../add_source_popup.dart';

class SourceLocationSection extends StatelessWidget {
  final SourceLocationType selectedLocationType;
  final Function(SourceLocationType) onLocationTypeChanged;
  final bool isFromBuildingPage;

  const SourceLocationSection({
    super.key,
    required this.selectedLocationType,
    required this.onLocationTypeChanged,
    required this.isFromBuildingPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Location',
          style: context.textTheme.l1Medium.copyWith(
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        /// Toggle
        FusionRadioChipSelector<SourceLocationType>(
          selected: selectedLocationType,
          options: SourceLocationType.values,
          labelBuilder: (SourceLocationType type) => type == SourceLocationType.zone ? 'Zone' : 'Equipment Location',
          onChanged: onLocationTypeChanged,
        ),

        const SizedBox(height: 20),

        /// Zone Flow
      ],
    );
  }
}
