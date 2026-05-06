import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scheduler_config.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodel/scheduler_form_viewmodel.dart';

class WeeklyDaySelection extends StatelessWidget {
  const WeeklyDaySelection();

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulerFormViewModel>(
      builder: (
        BuildContext context,
        SchedulerFormViewModel viewModel,
        Widget? child,
      ) {
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_day_selection"),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                semanticId: 'scheduler_form_timing_section_day_selection_label',
                text: "On Days",
                style: context.textTheme.b3Medium,
              ),
              const SizedBox(height: 10),
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_day_selection_grid"),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (final RecurrenceDay day in RecurrenceDay.values)
                      _buildDayCheckbox(
                        context: context,
                        day: day,
                        isSelected: viewModel.recurrenceDays.contains(day),
                        onToggle: () {
                          if (viewModel.recurrenceDays.contains(day)) {
                            viewModel.removeRecurrenceDay(day);
                          } else {
                            viewModel.addRecurrenceDay(day);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCheckbox({
    required BuildContext context,
    required RecurrenceDay day,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FusionCheckbox(
            width: 14,
            height: 14,
            semanticId: 'timing_section_day_checkbox',
            onChanged: onToggle,
            value: isSelected,
          ),
          const SizedBox(height: 4),
          FusionAppText(
            semanticId: 'timing_section_day_checkbox_label',
            text: day.name.substring(0, 3).toUpperCase(),
            style: context.textTheme.l1Regular.copyWith(
              color: context.colorScheme.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
