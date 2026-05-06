import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scheduler_config.dart';

import '../../../../viewmodel/scheduler_form_viewmodel.dart';

class OccurrenceSelector extends StatefulWidget {
  const OccurrenceSelector({required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<OccurrenceSelector> createState() => OccurrenceSelectorState();
}

class OccurrenceSelectorState extends State<OccurrenceSelector> {
  RecurrenceType? _hoveredType;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_occurrence_section"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(semanticId: 'scheduler_form_occurrence_section_label', text: "Occurrence", style: context.textTheme.b3Medium),
          const SizedBox(height: 8),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_occurrence_selection"),
            child: Row(
              children: <Widget>[
                for (final RecurrenceType type in RecurrenceType.values) ...<Widget>[
                  Expanded(
                    child: _buildOption(
                      context: context,
                      type: type,
                      label: type.label,
                      isSelected: widget.formViewModel.recurrenceType == type,
                      isHovering: _hoveredType == type,
                      onTap: () {
                        widget.formViewModel.recurrenceType = type;
                        // For daily/weekly, auto-set startDate to today if no date range
                        if (type != RecurrenceType.none && widget.formViewModel.startDate == null) {
                          widget.formViewModel.startDate = DateTime.now();
                        }
                      },
                    ),
                  ),
                  if (type != RecurrenceType.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required RecurrenceType type,
    required String label,
    required bool isSelected,
    required bool isHovering,
    required VoidCallback onTap,
  }) {
    final bool highlight = isSelected || isHovering;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredType = type),
      onExit: (_) {
        if (_hoveredType == type) {
          setState(() => _hoveredType = null);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "scheduler_form_occurrence_option_${type.index}"),
          label: type.label,
          isSelected: isSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: highlight ? context.colorScheme.elevation2 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.strokeLight,
                width: 1,
              ),
              // boxShadow: <BoxShadow>[
              //   BoxShadow(
              //     color: context.colorScheme.shadowDark,
              //     blurRadius: 1,
              //     offset: const Offset(-2, -2),
              //     blurStyle: BlurStyle.inner,
              //   ),
              //   BoxShadow(
              //     color: context.colorScheme.shadowLight,
              //     blurRadius: 1,
              //     offset: const Offset(2, 2),
              //     blurStyle: BlurStyle.inner,
              //   ),
              //   BoxShadow(
              //     color: context.colorScheme.elevation1,
              //     blurRadius: 4,
              //     blurStyle: BlurStyle.inner,
              //   ),
              // ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FusionCheckbox(
                  value: isSelected,
                  shape: BoxShape.circle,
                  onChanged: onTap,
                  semanticId: '',
                ),
                const SizedBox(width: 8),
                FusionAppText(text: label, style: context.textTheme.b3Medium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
