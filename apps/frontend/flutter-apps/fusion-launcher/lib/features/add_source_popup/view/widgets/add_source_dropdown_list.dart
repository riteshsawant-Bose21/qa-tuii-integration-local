import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/add_sources_popup/add_sources_keys.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../../core/models/products_data.dart';
import 'common_widgets/add_sources_dropdown.dart';

class SourceDropdownList extends StatelessWidget {
  final List<SourceData?> selectedSources;
  final List<SourceData> items;
  final Function(int index, SourceData value) onChanged;

  const SourceDropdownList({
    super.key,
    required this.selectedSources,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSources.isEmpty) return const SizedBox();
    return Column(
      children: <Widget>[
        ...List<Widget>.generate(selectedSources.length, (int index) {
          final SourceData? selectedItem = selectedSources.elementAtOrNull(index);

          return SemanticHelper.container(
            testId: SemanticHelper.createTestId(
              SemanticTypes.container,
              '${FusionTestKeys.instance.addSourceSectionItem}_$index',
            ),
            child: FusionOutlinedDropdown<SourceData>(
              value: selectedItem,
              label: 'Select Media Source',
              hint: 'Select source',
              items: items,
              onChanged: (SourceData newValue) => onChanged(index, newValue),

              itemLabelBuilder: (SourceData option) => option.name,

              itemWidgetBuilder: (BuildContext context, SourceData option, bool isSelected) {
                return SemanticHelper.container(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.container,
                    'add_source_section_item_label_$index',
                  ),
                  child: Row(
                    children: <Widget>[
                      Image.asset(option.assetPath, height: 14, width: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FusionAppText(
                          maxLine: 1,
                          text: option.name,
                          style: Theme.of(context).textTheme.b3Regular,
                        ),
                      ),
                      if (isSelected) FusionIcon.icon(Icons.check, size: 14, color: context.colorScheme.iconWhite),
                    ],
                  ),
                );
              },

              selectedItemBuilder: (BuildContext context, SourceData option) {
                return Row(
                  children: <Widget>[
                    Image.asset(option.assetPath, height: 14, width: 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FusionAppText(
                        maxLine: 1,
                        text: option.name,
                        style: Theme.of(context).textTheme.b3Regular,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
