import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import 'package:fusion_lib/constants/semantics/features/add_sources_popup/add_sources_keys.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/models/project_entities/mix_scenes.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';

import '../../../../core/models/products_data.dart';
import '../../view_model/add_source_viewmodel.dart';
import 'common_widgets/add_sources_dropdown.dart';

class SourceConnectionSection extends StatelessWidget {
  final SourceSectionType selectedSectionType;
  final List<SourceData?> selectedSources;

  final SignalType? selectedSignalType;
  final List<SignalType> signalTypes;
  final Function(SignalType) onSignalTypeChanged;

  final SourceConnectionType? selectedConnectionType;
  final Function(SourceConnectionType) onConnectionChanged;

  const SourceConnectionSection({
    super.key,
    required this.selectedSectionType,
    required this.selectedSources,
    required this.selectedSignalType,
    required this.signalTypes,
    required this.onSignalTypeChanged,
    required this.selectedConnectionType,
    required this.onConnectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final SourceData? firstSource = selectedSources.firstOrNull;

    /// Guard condition (matches your original logic)
    final bool shouldShow =
        (selectedSectionType == SourceSectionType.mediaSources || selectedSectionType == SourceSectionType.microPhone) && firstSource != null;

    if (!shouldShow) return const SizedBox();

    final List<SourceConnectionType> connectionTypes = firstSource.supportedConnectionTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Signal Type (only for mediaSources)
        if (selectedSectionType == SourceSectionType.mediaSources) ...<Widget>[
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(
              SemanticTypes.container,
              FusionTestKeys.instance.addSourceSectionSignalTypeRadioGroup,
            ),
            child: FusionRadioChipSelector<SignalType>(
              selected: selectedSignalType,
              options: signalTypes,
              labelBuilder: (SignalType type) => type.displayName,
              onChanged: onSignalTypeChanged,
            ),
          ),
          const SizedBox(height: 20),
        ],

        /// Connection Dropdown
        FusionOutlinedDropdown<SourceConnectionType>(
          label: 'Connection',
          hint: 'Select Connection',
          value: selectedConnectionType,
          items: connectionTypes,
          itemLabelBuilder: (SourceConnectionType item) => item.displayName,
          onChanged: onConnectionChanged,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
