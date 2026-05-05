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
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/occurrence_selector.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/sceduler_name_field.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler/widgets/schedule_timeing_secion.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';
import '../../../viewmodel/scheduler_form_viewmodel.dart';
import '../../../viewmodel/scheduler_viewmodel.dart';

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
              ScheduleNameField(formViewModel: formViewModel),
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              const SizedBox(height: 20),
              OccurrenceSelector(formViewModel: formViewModel),
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              const SizedBox(height: 20),
              ScheduleTimingSection(formViewModel: formViewModel),
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

    final ValueNotifier<bool> buttonEnabled = ValueNotifier<bool>(false);

    void updateEnabled() {
      final bool valid =
          formViewModel.color != null &&
          formViewModel.color!.isNotEmpty &&
          formViewModel.name.text.trim().isNotEmpty &&
          (formViewModel.recurrenceType != RecurrenceType.weekly || formViewModel.recurrenceDays.isNotEmpty) &&
          formViewModel.startDate != null;
      buttonEnabled.value = valid;
    }

    formViewModel.addListener(updateEnabled);

    await FusionDrawer.show<void>(
      context: context,
      semanticId: 'scheduler_form',
      title: initial == null ? "Create Schedule" : "Edit Schedule",
      content: ChangeNotifierProvider<SchedulerFormViewModel>.value(
        value: formViewModel,
        child: SchedulerForm(viewModel: viewModel, initial: initial),
      ),
      buttonLabel: initial == null ? "Create Schedule" : "Edit Schedule",
      buttonEnabledNotifier: buttonEnabled,
      onButtonPressed: () async {
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

    formViewModel.removeListener(updateEnabled);
    buttonEnabled.dispose();
    formViewModel.dispose();
  }
}
