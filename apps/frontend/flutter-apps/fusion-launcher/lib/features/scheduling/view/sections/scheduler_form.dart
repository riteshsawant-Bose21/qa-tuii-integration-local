// import 'package:calendar_date_picker2/calendar_date_picker2.dart';
// import 'package:flutter/material.dart';
// import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../../viewmodel/scheduler_form_viewmodel.dart';
// import '../../viewmodel/scheduler_viewmodel.dart';
//
// class SchedulerForm extends StatelessWidget {
//   const SchedulerForm({super.key, required this.viewModel, this.initial});
//   final SchedulerViewmodel viewModel;
//   final ScheduleConfig? initial;
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       constraints: const BoxConstraints(maxWidth: 750),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
//       child: ChangeNotifierProvider<SchedulerFormViewModel>(
//         create:
//             (BuildContext context) => SchedulerFormViewModel(
//               viewModel: viewModel,
//               initial: initial,
//             ),
//
//         child: Material(
//           color: Colors.transparent,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: <Widget>[
//               /// Header
//               Container(
//                 decoration: BoxDecoration(
//                   color: context.colorScheme.elevation1,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     topRight: Radius.circular(12),
//                   ),
//                   border: Border.all(
//                     width: 1,
//                     color: context.colorScheme.elevation2,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: <Widget>[
//                     const SizedBox(
//                       width: 10,
//                     ),
//                     FusionAppText(
//                       text: initial == null ? "Create Schedule" : "Edit Schedule",
//                       style: context.textTheme.bodyMedium,
//                     ),
//                     const Spacer(),
//                     SemanticHelper.button(
//                       testId: SemanticHelper.createTestId(
//                         SemanticTypes.button,
//                         "scheduler_form_close_button",
//                       ),
//                       child: IconButton(
//                         icon: const Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 16,
//                         ),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Flexible(
//                 child: Consumer<SchedulerFormViewModel>(
//                   builder: (
//                     BuildContext context,
//                     SchedulerFormViewModel viewModel,
//                     Widget? child,
//                   ) {
//                     return Container(
//                       padding: const EdgeInsets.all(15.0),
//                       decoration: BoxDecoration(
//                         color: context.colorScheme.elevation1.withAlpha(120),
//                         borderRadius: const BorderRadius.only(
//                           bottomLeft: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                         border: Border(
//                           bottom: BorderSide(
//                             width: 1,
//                             color: context.colorScheme.elevation2,
//                           ),
//                           left: BorderSide(
//                             width: 1,
//                             color: context.colorScheme.elevation2,
//                           ),
//                           right: BorderSide(
//                             width: 1,
//                             color: context.colorScheme.elevation2,
//                           ),
//                         ),
//                       ),
//
//                       child: SingleChildScrollView(
//                         child: Form(
//                           key: viewModel.key,
//                           child: Column(
//                             spacing: 24,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               Row(
//                                 children: <Widget>[
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: <Widget>[
//                                         /// Zone Name Field
//                                         FusionAppText(
//                                           text: "Schedule Name",
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.bodySmall?.copyWith(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         FusionTextField(
//                                           semanticFieldId: 'scheduler_form_name_field',
//                                           controller: viewModel.name,
//                                           hintText: "Enter schedule name",
//                                           decoration: InputDecoration(
//                                             hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
//                                             counterText: '',
//                                             fillColor: context.colorScheme.elevation2,
//                                             filled: true,
//                                             border: const OutlineInputBorder(
//                                               borderSide: BorderSide(
//                                                 color: Colors.transparent,
//                                               ),
//                                             ),
//                                             enabledBorder: const OutlineInputBorder(
//                                               borderSide: BorderSide(
//                                                 color: Colors.transparent,
//                                               ),
//                                             ),
//                                             focusedBorder: const OutlineInputBorder(
//                                               borderSide: BorderSide(
//                                                 color: Colors.transparent,
//                                               ),
//                                             ),
//                                             isDense: true,
//                                             contentPadding: const EdgeInsets.symmetric(
//                                               vertical: 8,
//                                               horizontal: 12,
//                                             ),
//                                           ),
//                                           onChanged: (String value) {},
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Expanded(child: Container()),
//                                 ],
//                               ),
//
//                               /// Color Picker Placeholder
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: <Widget>[
//                                   FusionAppText(
//                                     text: "Color",
//                                     style: Theme.of(
//                                       context,
//                                     ).textTheme.bodySmall?.copyWith(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//
//                                   /// Color Grid
//                                   SizedBox(
//                                     width: 400,
//                                     child: SemanticHelper.container(
//                                       testId: SemanticHelper.createTestId(
//                                         SemanticTypes.container,
//                                         "scheduler_form_color_grid",
//                                       ),
//                                       child: GridView.builder(
//                                         shrinkWrap: true,
//                                         physics: const NeverScrollableScrollPhysics(),
//                                         gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                                           maxCrossAxisExtent: 20,
//                                           crossAxisSpacing: 12,
//                                           mainAxisSpacing: 12,
//                                         ),
//                                         itemCount: Zone.zoneColors.length,
//                                         itemBuilder: (
//                                           BuildContext context,
//                                           int index,
//                                         ) {
//                                           final String hexCode = Zone.zoneColors[index];
//                                           final Color color = hexToColor(
//                                             hexCode,
//                                           );
//                                           final bool isSelected = viewModel.color == hexCode;
//
//                                           return SemanticHelper.container(
//                                             testId: SemanticHelper.createTestId(
//                                               SemanticTypes.container,
//                                               "scheduler_form_color_option_$index",
//                                             ),
//                                             child: GestureDetector(
//                                               onTap: () {
//                                                 viewModel.color = hexCode;
//                                               },
//                                               child: Container(
//                                                 decoration: BoxDecoration(
//                                                   color: color,
//                                                   borderRadius: BorderRadius.circular(4),
//                                                   border:
//                                                       isSelected
//                                                           ? Border.all(
//                                                             color: context.colorScheme.primaryBlack,
//                                                             width: 2,
//                                                           )
//                                                           : null,
//                                                 ),
//                                                 child:
//                                                     isSelected
//                                                         ? SemanticHelper.button(
//                                                           testId: SemanticHelper.createTestId(
//                                                             SemanticTypes.button,
//                                                             "scheduler_form_color_selected_icon_$index",
//                                                           ),
//                                                           child: Container(
//                                                             decoration: BoxDecoration(
//                                                               color: context.colorScheme.primaryBlack.withOpacity(
//                                                                 0.2,
//                                                               ),
//                                                               borderRadius: BorderRadius.circular(
//                                                                 4,
//                                                               ),
//                                                             ),
//                                                             child: const Icon(
//                                                               Icons.check,
//                                                               color: Colors.white,
//                                                               size: 16,
//                                                             ),
//                                                           ),
//                                                         )
//                                                         : null,
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//
//                                 children: <Widget>[
//                                   FusionAppText(
//                                     text: "Recurrence",
//                                     style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   RadioGroup<RecurrenceType>(
//                                     groupValue: viewModel.recurrenceType,
//                                     onChanged: (RecurrenceType? selected) {
//                                       if (selected != null) {
//                                         viewModel.recurrenceType = selected;
//                                       }
//                                     },
//                                     child: Row(
//                                       children: <Widget>[
//                                         for (final RecurrenceType type in RecurrenceType.values)
//                                           Padding(
//                                             padding: const EdgeInsets.only(
//                                               right: 12.0,
//                                             ),
//                                             child: Row(
//                                               children: <Widget>[
//                                                 Radio<RecurrenceType>(
//                                                   value: type,
//                                                   fillColor: WidgetStateColor.resolveWith(
//                                                     (
//                                                       Set<WidgetState> states,
//                                                     ) => context.colorScheme.iconWhite,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   type.label,
//                                                   style: context.textTheme.bodySmall,
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                   // FusionSegmentedButton<RecurrenceType>(
//                                   //   value: viewModel.recurrenceType,
//                                   //   labels: <RecurrenceType, String>{
//                                   //     RecurrenceType.none: RecurrenceType.none.label,
//                                   //     RecurrenceType.daily: RecurrenceType.daily.label,
//                                   //     RecurrenceType.weekly: RecurrenceType.weekly.label,
//                                   //   },
//                                   //   onChanged: (RecurrenceType value) {
//                                   //     viewModel.recurrenceType = value;
//                                   //   },
//                                   // ),
//                                 ],
//                               ),
//                               // FusionAppText(
//                               //   text: "Select Date Range",
//                               //   style: context.textTheme.bodySmall?.copyWith(
//                               //     fontWeight: FontWeight.w500,
//                               //   ),
//                               // ),
//                               AnimatedSize(
//                                 duration: const Duration(milliseconds: 200),
//                                 alignment: Alignment.centerLeft,
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: <Widget>[
//                                     _DatePickerField(
//                                       label: "From",
//                                       selectedDate: viewModel.startDate,
//                                       onDateSelected: (DateTime date) {
//                                         viewModel.startDate = date;
//                                       },
//                                       validator: (DateTime? date) {
//                                         if (viewModel.startDate == null) {
//                                           return "Please select a start date";
//                                         }
//                                         return null;
//                                       },
//                                     ),
//                                     if (viewModel.recurrenceType != RecurrenceType.none) ...<Widget>[
//                                       const SizedBox(width: 12),
//                                       _DatePickerField(
//                                         validator: (DateTime? value) {
//                                           if (viewModel.endDate == null) {
//                                             return null;
//                                           }
//                                           if (viewModel.startDate != null &&
//                                               viewModel.endDate!.isBefore(
//                                                 viewModel.startDate!,
//                                               )) {
//                                             return "End date cannot be before start date";
//                                           }
//                                           return null;
//                                         },
//                                         label: "To",
//                                         selectedDate: viewModel.endDate,
//                                         minDate: viewModel.startDate,
//                                         onDateSelected: (DateTime date) {
//                                           viewModel.endDate = date;
//                                         },
//                                       ),
//                                     ],
//                                     const SizedBox(width: 12),
//                                     _TimePicker(
//                                       title: "Start",
//                                       time: viewModel.startTime,
//                                       onChanged: (TimeOfDay value) {
//                                         viewModel.startTime = value;
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               AnimatedSize(
//                                 duration: const Duration(milliseconds: 200),
//                                 child: switch (viewModel.recurrenceType) {
//                                   RecurrenceType.weekly => const _WeeklyDaySelection(),
//                                   _ => const SizedBox(),
//                                 },
//                               ),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 children: <Widget>[
//                                   FusionOutlinedButton(
//                                     textStyle: context.textTheme.bodySmall,
//                                     accessLabel: 'scheduler_form_cancel_button',
//                                     label: "Cancel",
//                                     onTap: () {
//                                       Navigator.pop(context);
//                                     },
//                                   ),
//                                   const SizedBox(width: 12),
//                                   FusionButton(
//                                     label: "Done",
//                                     accessLabel: 'scheduler_form_done_button',
//                                     isActive: viewModel.canEnableSubmit,
//                                     textStyle: context.textTheme.bodySmall?.copyWith(
//                                       color: viewModel.canEnableSubmit ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite.withAlpha(120),
//                                     ),
//                                     onTap: () async {
//                                       try {
//                                         final bool value = await viewModel.submit(initial);
//                                         if (value) {
//                                           Navigator.pop(context);
//                                         }
//                                       } catch (e) {
//                                         FusionToast.error(
//                                           context,
//                                           message: e.toString(),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                   const SizedBox(width: 12),
//                                 ],
//                               ),
//                               // const SizedBox(height: 24),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   static Future<void> show(
//     BuildContext context,
//     SchedulerViewmodel viewModel, {
//     ScheduleConfig? initial,
//   }) async {
//     await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return SchedulerForm(viewModel: viewModel, initial: initial);
//       },
//     );
//   }
// }
//
import 'dart:math' as math;
import 'dart:ui' as painting;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../projects/widget/building/side_panel_widgets/properties/schematic_properties.dart';
import '../../viewmodel/scheduler_form_viewmodel.dart';
import '../../viewmodel/scheduler_viewmodel.dart';

class SchedulerForm extends StatelessWidget {
  const SchedulerForm({super.key, required this.viewModel, this.initial});
  final SchedulerViewmodel viewModel;
  final ScheduleConfig? initial;

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulerFormViewModel>(
      builder: (
        BuildContext context,
        SchedulerFormViewModel formViewModel,
        Widget? child,
      ) {
        return Form(
          key: formViewModel.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ScheduleNameField(formViewModel: formViewModel),
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              const SizedBox(height: 20),
              _OccurrenceSelector(formViewModel: formViewModel),
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              const SizedBox(height: 20),
              _ScheduleTimingSection(formViewModel: formViewModel),
            ],
          ),
        );
      },
    );
  }

  static Future<void> show(
    BuildContext context,
    SchedulerViewmodel viewModel, {
    ScheduleConfig? initial,
  }) async {
    final SchedulerFormViewModel formViewModel = SchedulerFormViewModel(
      viewModel: viewModel,
      initial: initial,
    );

    await FusionDrawer.show<void>(
      context: context,
      semanticId: 'scheduler_form',
      title: initial == null ? "Create Schedule" : "Edit Schedule",
      content: ChangeNotifierProvider<SchedulerFormViewModel>.value(
        value: formViewModel,
        child: SchedulerForm(viewModel: viewModel, initial: initial),
      ),
      buttonLabel: initial == null ? "Create Schedule" : "Edit Schedule",
      onButtonPressed: () async {
        if (!(formViewModel.key.currentState?.validate() ?? false)) {
          return;
        }
        if (formViewModel.color == null || formViewModel.color!.isEmpty) {
          FusionToast.error(context, message: "Please select a color");
          return;
        }
        if (formViewModel.name.text.trim().isEmpty) {
          FusionToast.error(context, message: "Please enter a schedule name");
          return;
        }
        if (formViewModel.recurrenceType == RecurrenceType.weekly && formViewModel.recurrenceDays.isEmpty) {
          FusionToast.error(context, message: "Please select at least one day");
          return;
        }
        if (formViewModel.startDate == null) {
          FusionToast.error(context, message: "Please select a date");
          return;
        }
        try {
          final bool value = await formViewModel.submit(initial);
          if (value && context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            FusionToast.error(context, message: e.toString());
          }
        }
      },
    );

    formViewModel.dispose();
  }
}

// ============================================================
// Schedule Name + Color Picker
// ============================================================
class _ScheduleNameField extends StatefulWidget {
  const _ScheduleNameField({required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<_ScheduleNameField> createState() => _ScheduleNameFieldState();
}

class _ScheduleNameFieldState extends State<_ScheduleNameField> {
  bool _showColorGrid = false;
  bool _isHovering = false;
  bool _isHoveringField = false;

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
                            color: formViewModel.color != null ? hexToColor(formViewModel.color!) : context.colorScheme.volumeYellow,
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
              duration: const Duration(milliseconds: 400),
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

// ============================================================
// Occurrence (Weekly / Daily / Once)
// ============================================================
class _OccurrenceSelector extends StatefulWidget {
  const _OccurrenceSelector({required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<_OccurrenceSelector> createState() => _OccurrenceSelectorState();
}

class _OccurrenceSelectorState extends State<_OccurrenceSelector> {
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
                      onTap: () => widget.formViewModel.recurrenceType = type,
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
            padding: const EdgeInsets.all(8),
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
                Flexible(
                  child: FusionAppText(text: label, style: context.textTheme.l1Regular),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Timing Section (Set Time + On Days + Set Date / Date Range)
// ============================================================
class _ScheduleTimingSection extends StatefulWidget {
  const _ScheduleTimingSection({required this.formViewModel});
  final SchedulerFormViewModel formViewModel;

  @override
  State<_ScheduleTimingSection> createState() => _ScheduleTimingSectionState();
}

class _ScheduleTimingSectionState extends State<_ScheduleTimingSection> {
  bool _dateRangeEnabled = false;
  bool _showInlineClock = false;
  _DateFieldTarget? _openField;
  _ClockMode _clockMode = _ClockMode.hour;
  _TimePickerController? _timePickerController;
  _DateFieldTarget? _hoveredField;
  @override
  void initState() {
    super.initState();
    _dateRangeEnabled = widget.formViewModel.startDate != null || widget.formViewModel.endDate != null;
  }

  @override
  Widget build(BuildContext context) {
    final SchedulerFormViewModel formViewModel = widget.formViewModel;
    final RecurrenceType type = formViewModel.recurrenceType;
    final bool isOnce = type == RecurrenceType.none;
    final bool isWeekly = type == RecurrenceType.weekly;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Set Time header
          Row(
            children: <Widget>[
              FusionAppText(
                semanticId: 'scheduler_form_timing_section_label',
                text: "Set Time",
                style: context.textTheme.b3Medium,
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() => _showInlineClock = !_showInlineClock);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FusionIcon.icon(
                    semanticId: 'scheduler_form_timing_section_time_input_type_icon',
                    _showInlineClock ? Icons.keyboard_alt_outlined : Icons.access_time,
                    size: 16,
                    color: context.colorScheme.iconDefault,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            alignment: Alignment.topCenter,
            curve: Curves.easeOut,
            child: SizedBox(
              width: double.infinity,
              child:
                  _showInlineClock
                      ? SemanticHelper.container(
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "scheduler_form_timing_section_inline_clock",
                        ),
                        value: '${formViewModel.startTime.hour}:${formViewModel.startTime.minute}',
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _InlineClockPicker(
                            mode: _clockMode,
                            time: formViewModel.startTime,
                            onChanged: (TimeOfDay value) {
                              formViewModel.startTime = value;
                            },
                            onHourSelected: () {
                              _timePickerController?.focusMinute();
                            },
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_time_input"),
            value: '${formViewModel.startTime.hour}:${formViewModel.startTime.minute}',
            child: _TimePicker(
              mainAxisAlignment: _showInlineClock ? MainAxisAlignment.center : MainAxisAlignment.start,
              time: formViewModel.startTime,
              onChanged: (TimeOfDay value) {
                formViewModel.startTime = value;
              },
              onFieldFocused: (_ClockMode mode) {
                if (_clockMode != mode) {
                  setState(() => _clockMode = mode);
                }
              },
              onReady: (_TimePickerController controller) {
                _timePickerController = controller;
              },
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
          const SizedBox(height: 20),

          /// Weekly only: On Days
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isWeekly ? _buildWeeklyDaySelection(context) : const SizedBox.shrink(),
          ),

          /// Once → single Set Date.  Weekly/Daily → toggleable Set Date Range.
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_date_input"),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: isOnce ? _buildSingleDate(context, formViewModel) : _buildDateRange(context, formViewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar({
    required DateTime? selectedDate,
    required DateTime? minDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    final TextStyle baseDayStyle = context.textTheme.l1Regular.withColor(
      context.colorScheme.textPrimary,
    );

    return _CalendarWithOverlayPickers(
      selectedDate: selectedDate,
      minDate: minDate,
      onPicked: onPicked,
      baseDayStyle: baseDayStyle,
    );
  }

  Widget _buildDateFieldBox({
    required _DateFieldTarget target,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    bool hasError = false,
    bool isOpen = false,
    required String semanticId,
  }) {
    final bool isHovering = _hoveredField == target;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_timing_section_${semanticId}_date_input_field"),
      value: selectedDate.toString(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredField = target),
          onExit: (_) {
            if (_hoveredField == target) {
              setState(() => _hoveredField = null);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: (isOpen || isHovering) ? context.colorScheme.elevation2 : Colors.transparent,
              border: Border.all(
                color: isOpen ? Colors.transparent : context.colorScheme.strokeLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    semanticId: 'scheduler_form_timing_section_date_input_label',
                    text: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate) : "dd/mm/yyyy",
                    style: context.textTheme.b3Regular.copyWith(
                      color: selectedDate != null ? context.colorScheme.textPrimary : context.colorScheme.textBody,
                    ),
                  ),
                ),
                FusionIcon.icon(
                  semanticId: 'scheduler_form_timing_section_date_input_icon',
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: context.colorScheme.iconDefault,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleDate(
    BuildContext context,
    SchedulerFormViewModel formViewModel,
  ) {
    return Column(
      key: const ValueKey<String>('single_date'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(semanticId: 'scheduler_form_timing_section_date_input_label', text: "Set Date", style: context.textTheme.b3Medium),
        const SizedBox(height: 8),
        _buildDateFieldBox(
          semanticId: 'single',
          target: _DateFieldTarget.single,
          selectedDate: formViewModel.startDate,
          isOpen: _openField == _DateFieldTarget.single,

          hasError: false,
          onTap: () {
            setState(() {
              _openField = _openField == _DateFieldTarget.single ? null : _DateFieldTarget.single;
            });
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child:
              _openField == _DateFieldTarget.single
                  ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        "scheduler_form_timing_section_date_input_calendar",
                      ),
                      child: _buildCalendar(
                        selectedDate: formViewModel.startDate,
                        minDate: null,
                        onPicked: (DateTime date) {
                          formViewModel.startDate = date;
                          formViewModel.endDate = date;
                          setState(() => _openField = null);
                        },
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDateRange(
    BuildContext context,
    SchedulerFormViewModel formViewModel,
  ) {
    return Column(
      key: const ValueKey<String>('date_range'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FusionSwitch(
              semanticId: 'scheduler_form_timing_section_date_range_input_switch',
              width: 44,
              height: 24,
              value: _dateRangeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _dateRangeEnabled = value;
                  if (!value) {
                    formViewModel.startDate = null;
                    formViewModel.endDate = null;
                    _openField = null;
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            FusionAppText(
              semanticId: 'scheduler_form_timing_section_date_range_input_label',
              text: "Set Date Range",
              style: context.textTheme.b3Medium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _dateRangeEnabled ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !_dateRangeEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            semanticId: 'scheduler_form_timing_section_date_range_input_from_label',
                            text: "From",
                            style: context.textTheme.l1Medium,
                          ),
                          const SizedBox(height: 8),
                          _buildDateFieldBox(
                            semanticId: 'from',
                            target: _DateFieldTarget.from,
                            selectedDate: formViewModel.startDate,
                            hasError: false,
                            isOpen: _openField == _DateFieldTarget.from,
                            onTap: () {
                              setState(() {
                                _openField = _openField == _DateFieldTarget.from ? null : _DateFieldTarget.from;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: "To",
                            style: context.textTheme.l1Medium,
                          ),
                          const SizedBox(height: 8),
                          _buildDateFieldBox(
                            semanticId: 'to',
                            target: _DateFieldTarget.to,
                            selectedDate: formViewModel.endDate,
                            hasError: false,
                            isOpen: _openField == _DateFieldTarget.to,
                            onTap: () {
                              setState(() {
                                _openField = _openField == _DateFieldTarget.to ? null : _DateFieldTarget.to;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child:
                      _openField == _DateFieldTarget.from || _openField == _DateFieldTarget.to
                          ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildCalendar(
                              selectedDate: _openField == _DateFieldTarget.from ? formViewModel.startDate : formViewModel.endDate,
                              minDate: _openField == _DateFieldTarget.to ? formViewModel.startDate : null,
                              onPicked: (DateTime date) {
                                if (_openField == _DateFieldTarget.from) {
                                  formViewModel.startDate = date;
                                } else {
                                  formViewModel.endDate = date;
                                }
                                setState(() => _openField = null);
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyDaySelection(BuildContext context) {
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
              FusionAppText(semanticId: 'scheduler_form_timing_section_day_selection_label', text: "On Days", style: context.textTheme.b3Medium),
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

// ============================================================
// Time Picker (editable hour / minute + AM-PM + clock dialog)
// ============================================================
class _TimePicker extends StatefulWidget {
  const _TimePicker({
    required this.time,
    this.onChanged,
    this.onFieldFocused,
    this.onReady,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay>? onChanged;
  final ValueChanged<_ClockMode>? onFieldFocused;
  final ValueChanged<_TimePickerController>? onReady;
  final MainAxisAlignment mainAxisAlignment;

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerController {
  _TimePickerController({required this.focusHour, required this.focusMinute});
  final VoidCallback focusHour;
  final VoidCallback focusMinute;
}

class _TimePickerState extends State<_TimePicker> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final FocusNode _hourFocus;
  late final FocusNode _minuteFocus;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(
      text: widget.time.hourOfPeriod == 0 ? '12' : widget.time.hourOfPeriod.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: widget.time.minute.toString().padLeft(2, '0'),
    );
    _hourFocus =
        FocusNode()..addListener(() {
          if (_hourFocus.hasFocus) {
            widget.onFieldFocused?.call(_ClockMode.hour);
          } else {
            _onHourFocusChange();
          }
          setState(() {});
        });

    _minuteFocus =
        FocusNode()..addListener(() {
          if (_minuteFocus.hasFocus) {
            widget.onFieldFocused?.call(_ClockMode.minute);
          } else {
            _onMinuteFocusChange();
          }
          setState(() {});
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady?.call(
        _TimePickerController(
          focusHour: () => _hourFocus.requestFocus(),
          focusMinute: () => _minuteFocus.requestFocus(),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) _syncControllersFromWidget();
  }

  void _syncControllersFromWidget() {
    final String h = widget.time.hourOfPeriod == 0 ? '12' : widget.time.hourOfPeriod.toString().padLeft(2, '0');
    final String m = widget.time.minute.toString().padLeft(2, '0');
    if (_hourController.text != h) _hourController.text = h;
    if (_minuteController.text != m) _minuteController.text = m;
  }

  void _onHourFocusChange() {
    if (!_hourFocus.hasFocus) _commitHour();
  }

  void _onMinuteFocusChange() {
    if (!_minuteFocus.hasFocus) _commitMinute();
  }

  void _commitHour() {
    int h = int.tryParse(_hourController.text) ?? widget.time.hourOfPeriod;
    if (h < 1) h = 1;
    if (h > 12) h = 12;
    final bool isAM = widget.time.period == DayPeriod.am;
    final int hour24 = isAM ? (h == 12 ? 0 : h) : (h == 12 ? 12 : h + 12);
    _hourController.text = h.toString().padLeft(2, '0');
    widget.onChanged?.call(TimeOfDay(hour: hour24, minute: widget.time.minute));
  }

  void _commitMinute() {
    int m = int.tryParse(_minuteController.text) ?? widget.time.minute;
    if (m < 0) m = 0;
    if (m > 59) m = 59;
    _minuteController.text = m.toString().padLeft(2, '0');
    widget.onChanged?.call(TimeOfDay(hour: widget.time.hour, minute: m));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAM = widget.time.period == DayPeriod.am;
    final Color borderColor = context.colorScheme.strokeLight;

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      children: <Widget>[
        _TimeUnitBox(
          controller: _hourController,
          focusNode: _hourFocus,
          label: "Hour",
          borderColor: borderColor,
          onSubmitted: (_) => _commitHour(),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: FusionAppText(semanticId: 'timing_section_time_separator', text: ":", style: context.textTheme.labelLarge),
        ),
        const SizedBox(width: 6),
        _TimeUnitBox(
          controller: _minuteController,
          focusNode: _minuteFocus,
          label: "Minute",
          borderColor: borderColor,
          onSubmitted: (_) => _commitMinute(),
        ),
        const SizedBox(width: 10),
        _AmPmToggle(
          isAM: isAM,
          borderColor: borderColor,
          onChanged: (bool selectAM) {
            final TimeOfDay newTime = TimeOfDay(
              hour: selectAM ? (isAM ? widget.time.hour : (widget.time.hour - 12) % 24) : (isAM ? (widget.time.hour + 12) % 24 : widget.time.hour),
              minute: widget.time.minute,
            );
            widget.onChanged?.call(newTime);
          },
        ),
      ],
    );
  }
}

class _AmPmToggle extends StatefulWidget {
  const _AmPmToggle({
    required this.isAM,
    required this.borderColor,
    required this.onChanged,
  });

  final bool isAM;
  final Color borderColor;
  final ValueChanged<bool> onChanged; // true = AM, false = PM

  @override
  State<_AmPmToggle> createState() => _AmPmToggleState();
}

class _AmPmToggleState extends State<_AmPmToggle> {
  bool _hoverAM = false;
  bool _hoverPM = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 52,
          width: 38,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: context.colorScheme.elevation2,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: <Widget>[
              Expanded(
                child: _buildHalf(
                  context: context,
                  label: "AM",
                  selected: widget.isAM,
                  hovering: _hoverAM,
                  onHover: (bool v) => setState(() => _hoverAM = v),
                  onTap: () => widget.onChanged(true),
                  accent: context.colorScheme.strokeLight,
                ),
              ),
              Expanded(
                child: _buildHalf(
                  context: context,
                  label: "PM",
                  selected: !widget.isAM,
                  hovering: _hoverPM,
                  onHover: (bool v) => setState(() => _hoverPM = v),
                  onTap: () => widget.onChanged(false),
                  accent: context.colorScheme.strokeLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildHalf({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool hovering,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? context.colorScheme.elevation3
                    : hovering
                    ? accent
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FusionAppText(
            semanticId: 'timing_section_am_pm_toggle_label',
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: (selected || hovering) ? context.colorScheme.textPrimary : context.colorScheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

enum _DateFieldTarget { single, from, to }

enum _ClockMode { hour, minute }

class _InlineClockPicker extends StatefulWidget {
  const _InlineClockPicker({
    required this.time,
    required this.mode,
    required this.onChanged,
    this.onHourSelected,
  });

  final TimeOfDay time;
  final _ClockMode mode;
  final ValueChanged<TimeOfDay> onChanged;
  final VoidCallback? onHourSelected;

  @override
  State<_InlineClockPicker> createState() => _InlineClockPickerState();
}

class _InlineClockPickerState extends State<_InlineClockPicker> {
  static const double _size = 170;
  static const double _padding = 20;

  void _handlePan(Offset localPos) {
    const Offset center = Offset(_size / 2, _size / 2);
    final Offset delta = localPos - center;
    double angle = math.atan2(delta.dx, -delta.dy);
    if (angle < 0) angle += 2 * math.pi;

    if (widget.mode == _ClockMode.hour) {
      int hour = (angle / (2 * math.pi / 12)).round() % 12;
      if (hour == 0) hour = 12;

      final bool isAM = widget.time.period == DayPeriod.am;
      final int hour24 = isAM ? (hour == 12 ? 0 : hour) : (hour == 12 ? 12 : hour + 12);
      widget.onChanged(TimeOfDay(hour: hour24, minute: widget.time.minute));
    } else {
      final int minute = (angle / (2 * math.pi / 60)).round() % 60;
      widget.onChanged(TimeOfDay(hour: widget.time.hour, minute: minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanDown: (DragDownDetails d) => _handlePan(d.localPosition),
        onPanUpdate: (DragUpdateDetails d) => _handlePan(d.localPosition),
        onTapUp: (TapUpDetails d) {
          _handlePan(d.localPosition);
          if (widget.mode == _ClockMode.hour) {
            widget.onHourSelected?.call();
          }
        },
        child: CustomPaint(
          size: const Size(_size, _size),
          painter: _ClockPainter(
            time: widget.time,
            mode: widget.mode,
            faceColor: context.colorScheme.elevation2,
            numberColor: context.colorScheme.textBody,
            selectorColor: context.colorScheme.primaryColor,
            padding: _padding,
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.time,
    required this.mode,
    required this.faceColor,
    required this.numberColor,
    required this.selectorColor,
    required this.padding,
  });

  final TimeOfDay time;
  final _ClockMode mode;
  final Color faceColor;
  final Color numberColor;
  final Color selectorColor;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final double numberRadius = radius - padding;

    // Face
    canvas.drawCircle(center, radius, Paint()..color = faceColor);

    // Compute selector angle based on mode
    final double selectedAngle;
    if (mode == _ClockMode.hour) {
      final int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      selectedAngle = (selectedHour * 2 * math.pi / 12) - math.pi / 2;
    } else {
      selectedAngle = (time.minute * 2 * math.pi / 60) - math.pi / 2;
    }

    final Offset selectorPos = Offset(
      center.dx + numberRadius * math.cos(selectedAngle),
      center.dy + numberRadius * math.sin(selectedAngle),
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = selectorColor);

    // Hand line
    canvas.drawLine(
      center,
      selectorPos,
      Paint()
        ..color = selectorColor
        ..strokeWidth = 2,
    );

    // Selector circle
    canvas.drawCircle(selectorPos, 14, Paint()..color = selectorColor);

    // Number labels
    if (mode == _ClockMode.hour) {
      _drawHourLabels(canvas, center, numberRadius);
    } else {
      _drawMinuteLabels(canvas, center, numberRadius);
    }
  }

  void _drawHourLabels(Canvas canvas, Offset center, double numberRadius) {
    final int selectedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    for (int i = 1; i <= 12; i++) {
      final double angle = (i * 2 * math.pi / 12) - math.pi / 2;
      final Offset pos = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      _paintLabel(canvas, pos, i.toString(), i == selectedHour);
    }
  }

  void _drawMinuteLabels(Canvas canvas, Offset center, double numberRadius) {
    // Show 0, 5, 10, ... 55 (12 labels, same positions as hour dial)
    for (int i = 0; i < 12; i++) {
      final int minute = i * 5;
      final double angle = (minute * 2 * math.pi / 60) - math.pi / 2;
      final Offset pos = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      final bool isSelected = minute == time.minute;
      _paintLabel(canvas, pos, minute.toString().padLeft(2, '0'), isSelected);
    }
  }

  void _paintLabel(Canvas canvas, Offset pos, String text, bool isSelected) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? Colors.white : numberColor,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      textDirection: painting.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.mode != mode;
  }
}

class _CalendarWithOverlayPickers extends StatefulWidget {
  const _CalendarWithOverlayPickers({
    required this.selectedDate,
    required this.minDate,
    required this.onPicked,
    required this.baseDayStyle,
  });

  final DateTime? selectedDate;
  final DateTime? minDate;
  final ValueChanged<DateTime> onPicked;
  final TextStyle baseDayStyle;

  @override
  State<_CalendarWithOverlayPickers> createState() => _CalendarWithOverlayPickersState();
}

class _CalendarWithOverlayPickersState extends State<_CalendarWithOverlayPickers> {
  late DateTime _displayedMonth;
  final LayerLink _monthLink = LayerLink();
  final LayerLink _yearLink = LayerLink();
  final OverlayPortalController _monthController = OverlayPortalController();
  final OverlayPortalController _yearController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    final DateTime initial = widget.selectedDate ?? DateTime.now();
    final DateTime floor = _minAllowedMonth();
    _displayedMonth = DateTime(initial.year, initial.month, 1).isBefore(floor) ? floor : DateTime(initial.year, initial.month, 1);
  }

  DateTime _minAllowedMonth() {
    final DateTime min = widget.minDate ?? DateTime.now();
    return DateTime(min.year, min.month, 1);
  }

  bool get _canGoBack {
    final DateTime prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    return !prev.isBefore(_minAllowedMonth());
  }

  void _toggleMonth() {
    if (_yearController.isShowing) _yearController.hide();
    if (_monthController.isShowing) {
      _monthController.hide();
    } else {
      _monthController.show();
    }
    setState(() {});
  }

  void _toggleYear() {
    if (_monthController.isShowing) _monthController.hide();
    if (_yearController.isShowing) {
      _yearController.hide();
    } else {
      _yearController.show();
    }
    setState(() {});
  }

  void _selectMonth(int month) {
    final DateTime candidate = DateTime(_displayedMonth.year, month, 1);
    if (candidate.isBefore(_minAllowedMonth())) return;
    setState(() => _displayedMonth = candidate);
    _monthController.hide();
  }

  void _selectYear(int year) {
    final DateTime floor = _minAllowedMonth();
    final DateTime candidate = DateTime(year, _displayedMonth.month, 1);
    final DateTime adjusted = candidate.isBefore(floor) ? DateTime(year, floor.month, 1) : candidate;
    // If year < floor.year entirely, ignore (disabled in picker anyway).
    if (adjusted.isBefore(floor)) return;
    setState(() => _displayedMonth = adjusted);
    _yearController.hide();
  }

  void _prevMonth() {
    if (!_canGoBack) return;
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  void dispose() {
    if (_monthController.isShowing) _monthController.hide();
    if (_yearController.isShowing) _yearController.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime floor = _minAllowedMonth();
    final bool canGoBack = _canGoBack;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Custom header
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header'),
            child: Row(
              children: <Widget>[
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header_month_container'),
                  child: CompositedTransformTarget(
                    link: _monthLink,
                    child: OverlayPortal(
                      controller: _monthController,
                      overlayChildBuilder: (BuildContext ctx) {
                        final Set<int> disabled = <int>{};
                        for (int i = 0; i < 12; i++) {
                          final DateTime candidate = DateTime(_displayedMonth.year, i + 1, 1);
                          if (candidate.isBefore(floor)) disabled.add(i);
                        }
                        return _FloatingGridPicker(
                          semanticId: 'month',
                          link: _monthLink,
                          width: 244,
                          scrollable: false,
                          items: List<String>.generate(
                            12,
                            (int i) => _monthShort(i + 1),
                          ),
                          selectedIndex: _displayedMonth.month - 1,
                          disabledIndices: disabled,
                          onSelected: (int i) => _selectMonth(i + 1),
                          onDismiss: () {
                            _monthController.hide();
                            setState(() {});
                          },
                        );
                      },
                      child: _buildHeaderChip(
                        label: _monthName(_displayedMonth.month),
                        isOpen: _monthController.isShowing,
                        onTap: _toggleMonth,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header_year_container'),
                  child: CompositedTransformTarget(
                    link: _yearLink,
                    child: OverlayPortal(
                      controller: _yearController,
                      overlayChildBuilder: (BuildContext ctx) {
                        final int currentYear = DateTime.now().year;
                        final int floorYear = floor.year;

                        // Build a wide year range that always includes the currently displayed year
                        final int startYear = floorYear;
                        final int endYear = math.max(currentYear + 20, _displayedMonth.year + 5);
                        final List<int> years = <int>[
                          for (int y = startYear; y <= endYear; y++) y,
                        ];

                        final int selectedIdx = years.indexOf(_displayedMonth.year);
                        return _FloatingGridPicker(
                          semanticId: 'year',
                          offset: const Offset(-70, 6),
                          link: _yearLink,
                          width: 244,
                          scrollable: true,
                          items: years.map((int y) => y.toString()).toList(),
                          selectedIndex: selectedIdx,
                          disabledIndices: const <int>{},
                          onSelected: (int i) => _selectYear(years[i]),
                          onDismiss: () {
                            _yearController.hide();
                            setState(() {});
                          },
                        );
                      },
                      child: _buildHeaderChip(
                        label: _displayedMonth.year.toString(),
                        isOpen: _yearController.isShowing,
                        onTap: _toggleYear,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: canGoBack ? _prevMonth : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(
                      Icons.chevron_left,
                      size: 20,
                      color: canGoBack ? context.colorScheme.iconDefault : context.colorScheme.iconDefault.withAlpha(35),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _nextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.colorScheme.iconDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.77,
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  calendarType: CalendarDatePicker2Type.single,
                  firstDate: widget.minDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  disableModePicker: true,
                  hideMonthPickerDividers: true,
                  hideYearPickerDividers: true,
                  selectedDayHighlightColor: context.colorScheme.primaryWhite,
                  selectedDayTextStyle: widget.baseDayStyle.copyWith(
                    color: context.colorScheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                  daySplashColor: Colors.white10,
                  dayTextStyle: widget.baseDayStyle,
                  disabledDayTextStyle: widget.baseDayStyle.copyWith(
                    color: context.colorScheme.textDisabled,
                  ),
                  todayTextStyle: widget.baseDayStyle,
                  weekdayLabels: const <String>[
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ],
                  weekdayLabelTextStyle: context.textTheme.l1Regular.copyWith(color: context.colorScheme.textSecondary),
                  dayMaxWidth: 22,
                ),
                displayedMonthDate: _displayedMonth,
                value: <DateTime?>[widget.selectedDate],
                onValueChanged: (List<DateTime> dates) {
                  if (dates.isNotEmpty) widget.onPicked(dates.first);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  static String _monthShort(int m) {
    const List<String> names = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JLY',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return names[m - 1];
  }

  Widget _buildHeaderChip({
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FusionAppText(
              text: label,
              semanticId: 'calendar_header_month_label',
              style: context.textTheme.h6Bold.copyWith(
                color: context.colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            FusionIcon.icon(
              semanticId: 'calendar_header_month_icon',
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: context.colorScheme.iconWhite,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingGridPicker extends StatefulWidget {
  const _FloatingGridPicker({
    required this.semanticId,
    required this.link,
    required this.width,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onDismiss,
    this.disabledIndices = const <int>{},
    this.scrollable = false,
    this.offset = const Offset(-6, 6),
  });
  final String semanticId;
  final LayerLink link;
  final double width;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onDismiss;
  final Set<int> disabledIndices;
  final bool scrollable;
  final Offset offset;

  @override
  State<_FloatingGridPicker> createState() => _FloatingGridPickerState();
}

class _FloatingGridPickerState extends State<_FloatingGridPicker> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final Widget grid = SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        '${widget.semanticId}_picker_grid',
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        physics: widget.scrollable ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.9,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == widget.selectedIndex;
          final bool isDisabled = widget.disabledIndices.contains(index);
          final bool isHovered = _hoveredIndex == index;

          return MouseRegion(
            cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            onEnter: (_) {
              if (!isDisabled) setState(() => _hoveredIndex = index);
            },
            onExit: (_) {
              if (_hoveredIndex == index) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: InkWell(
              onTap: isDisabled ? null : () => widget.onSelected(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? context.colorScheme.elevation3
                          : isHovered
                          ? context.colorScheme.elevation3.withOpacity(0.5)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FusionAppText(
                  text: widget.items[index],
                  semanticId: 'calendar_header_${widget.semanticId}_item',
                  style: context.textTheme.l1Regular.copyWith(
                    color: isDisabled ? context.colorScheme.textPlaceholder : context.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: const SizedBox.shrink(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: widget.offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                  width: 1,
                ),
              ),
              child:
                  widget.scrollable
                      ? SizedBox(
                        height: 196,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: grid,
                        ),
                      )
                      : grid,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeUnitBox extends StatefulWidget {
  const _TimeUnitBox({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.borderColor,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Color borderColor;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TimeUnitBox> createState() => _TimeUnitBoxState();
}

class _TimeUnitBoxState extends State<_TimeUnitBox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = widget.focusNode.hasFocus;

    return Column(
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.text,
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Container(
            width: 46,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.borderColor,
                width: (hasFocus || _isHovering) ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: (hasFocus || _isHovering) ? context.colorScheme.elevation2 : Colors.transparent,
            ),
            child: TextField(
              cursorColor: context.colorScheme.elevation6,
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 2,
              style: context.textTheme.h6Regular,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                fillColor: Colors.transparent,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FusionAppText(
          semanticId: 'timing_section_hour_minute_label',
          text: widget.label,
          style: context.textTheme.l2Regular.copyWith(
            color: context.colorScheme.textBody,
          ),
        ),
      ],
    );
  }
}
