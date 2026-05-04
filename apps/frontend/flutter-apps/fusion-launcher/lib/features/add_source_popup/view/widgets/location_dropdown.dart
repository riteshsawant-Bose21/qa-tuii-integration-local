import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import 'package:fusion_lib/constants/semantics/features/add_sources_popup/add_sources_keys.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/listening_area_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../add_source_popup.dart';
import 'common_widgets/add_sources_dropdown.dart';

class SourceLocationSection extends StatelessWidget {
  final SourceLocationType selectedLocationType;
  final Function(SourceLocationType) onLocationTypeChanged;

  final ListeningArea? selectedListeningArea;
  final List<ListeningArea> listeningAreas;
  final Function(ListeningArea) onListeningAreaChanged;

  final bool isFromBuildingPage;

  final (String?, String?) zoneInfo;

  const SourceLocationSection({
    super.key,
    required this.selectedLocationType,
    required this.onLocationTypeChanged,
    required this.selectedListeningArea,
    required this.listeningAreas,
    required this.onListeningAreaChanged,
    required this.isFromBuildingPage,
    required this.zoneInfo,
  });

  @override
  Widget build(BuildContext context) {
    final (String? zoneName, String? subZoneName) = zoneInfo;

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
          labelBuilder: (SourceLocationType type) => type == SourceLocationType.zone ? 'Zone' : 'Equipment Loca...',
          onChanged: onLocationTypeChanged,
        ),

        const SizedBox(height: 20),

        /// Zone Flow
        if (selectedLocationType == SourceLocationType.zone) ...<Widget>[
          IgnorePointer(
            ignoring: isFromBuildingPage,
            child: Opacity(
              opacity: isFromBuildingPage ? 0.5 : 1.0,
              child: SemanticHelper.dropdown(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.dropdown,
                  FusionTestKeys.instance.addSourceSectionListeningAreaDropdown,
                ),
                value: selectedListeningArea?.name ?? '',
                child: FusionOutlinedDropdown<ListeningArea>(
                  label: 'Select Zone',
                  hint: 'Select Listening Area',
                  value: selectedListeningArea,
                  items: listeningAreas,
                  itemLabelBuilder: (ListeningArea item) => item.name,
                  onChanged: onListeningAreaChanged,

                  /// Dropdown list item
                  itemWidgetBuilder: (BuildContext context, ListeningArea option, bool isSelected) {
                    final String? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: option.id)?.name;

                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: '$floorName / ${option.name}',
                            maxLine: 1,
                            style: Theme.of(context).textTheme.b3Regular,
                          ),
                        ),
                        if (isSelected) Icon(Icons.check, size: 14, color: context.colorScheme.iconWhite),
                      ],
                    );
                  },

                  /// Selected item
                  selectedItemBuilder: (BuildContext context, ListeningArea option) {
                    final String? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: option.id)?.name;

                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: '$floorName / ${option.name}',
                            maxLine: 1,
                            style: Theme.of(context).textTheme.b3Medium,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          /// Zone Info (Read-only)
          if (zoneName != null || subZoneName != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (zoneName != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _infoBox(context, zoneName),
                ],
                if (subZoneName != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _infoBox(context, subZoneName),
                ],
              ],
            ),
        ],
      ],
    );
  }

  Widget _infoBox(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.strokeLight),
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FusionAppText(
        text: text,
        maxLine: 1,
        style: Theme.of(context).textTheme.b3Medium,
      ),
    );
  }
}
