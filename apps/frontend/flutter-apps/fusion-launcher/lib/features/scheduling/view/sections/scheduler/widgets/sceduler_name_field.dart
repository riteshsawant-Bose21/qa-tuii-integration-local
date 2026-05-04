import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/zone_model.dart';

import '../../../../../projects/widget/building/side_panel_widgets/schematic_properties.dart';
import '../../../../viewmodel/scheduler_form_viewmodel.dart';

class ScheduleNameField extends StatefulWidget {
  const ScheduleNameField({required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<ScheduleNameField> createState() => ScheduleNameFieldState();
}

class ScheduleNameFieldState extends State<ScheduleNameField> {
  bool _showColorGrid = false;
  bool _isHovering = false;
  bool _isHoveringField = false;
  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SchedulerFormViewModel formViewModel = widget.formViewModel;
    if (formViewModel.color == null) {
      final math.Random random = math.Random();
      final List<String> colors = Zone.zoneColors;
      final String randomColor = colors[random.nextInt(colors.length)];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formViewModel.color = randomColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SchedulerFormViewModel formViewModel = widget.formViewModel;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_name_field_section"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: 'scheduler_form_name_field_section_label',
            text: "Schedule Name",
            style: Theme.of(context).textTheme.b3Medium.withColor(context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringField = true),
            onExit: (_) => setState(() => _isHoveringField = false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                  width: 1,
                ),
                color: _isHoveringField ? context.colorScheme.elevation2 : Colors.transparent,
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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
              child: Row(
                children: <Widget>[
                  SemanticHelper.container(
                    value: formViewModel.color,
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_name_field_section_color_selection"),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isHovering = true),
                      onExit: (_) => setState(() => _isHovering = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _showColorGrid = !_showColorGrid);
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: formViewModel.color != null ? hexToColor(formViewModel.color!) : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: context.colorScheme.zone1Stroke,
                              width: 0.75,
                            ),
                          ),
                          child:
                              _isHovering
                                  ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FusionIcon.icon(
                                      Icons.edit,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FusionTextField(
                      maxLength: 30,
                      semanticFieldId: 'scheduler_form_name_field',
                      controller: formViewModel.name,
                      hintText: "Enter schedule name",
                      decoration: InputDecoration(
                        hintText: "Enter schedule name", // ← ensure hint shows
                        hintStyle: TextStyle(color: context.colorScheme.textPlaceholder),
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (String value) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_color_grid_section"),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              curve: Curves.easeOut,
              child: SizedBox(
                width: double.infinity,
                child:
                    _showColorGrid
                        ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: context.colorScheme.elevation4,
                                width: 1,
                              ),
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 16,
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: Zone.zoneColors.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String hexCode = Zone.zoneColors[index];
                                final Color color = hexToColor(hexCode);
                                final bool isSelected = formViewModel.color == hexCode;

                                return GestureDetector(
                                  onTap: () {
                                    formViewModel.color = hexCode;
                                    setState(() => _showColorGrid = false);
                                  },
                                  child: SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(
                                      SemanticTypes.container,
                                      "scheduler_form_color_grid",
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: context.colorScheme.primaryWhite,
                                                  width: 2,
                                                )
                                                : null,
                                      ),
                                      child:
                                          isSelected
                                              ? FusionIcon.icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 10,
                                              )
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
