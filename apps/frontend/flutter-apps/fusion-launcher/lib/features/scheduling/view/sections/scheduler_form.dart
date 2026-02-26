import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/scheduler_form_viewmodel.dart';
import '../../viewmodel/scheduler_viewmodel.dart';

class SchedulerForm extends StatelessWidget {
  const SchedulerForm({super.key, required this.viewModel, this.initial});
  final SchedulerViewmodel viewModel;
  final ScheduleConfig? initial;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 750),
      insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
      child: ChangeNotifierProvider<SchedulerFormViewModel>(
        create:
            (BuildContext context) => SchedulerFormViewModel(
              viewModel: viewModel,
              initial: initial,
            ),

        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Header
              Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    width: 1,
                    color: context.colorScheme.elevation2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(
                      width: 10,
                    ),
                    FusionAppText(text: initial == null ? "Create Schedule" : "Edit Schedule", style: context.textTheme.bodyMedium),
                    const Spacer(),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "scheduler_form_close_button"),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer<SchedulerFormViewModel>(
                  builder: (BuildContext context, SchedulerFormViewModel viewModel, Widget? child) {
                    return Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation1.withAlpha(120),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                          left: BorderSide(width: 1, color: context.colorScheme.elevation2),
                          right: BorderSide(width: 1, color: context.colorScheme.elevation2),
                        ),
                      ),

                      child: SingleChildScrollView(
                        child: Form(
                          key: viewModel.key,
                          child: Column(
                            spacing: 24,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        /// Zone Name Field
                                        FusionAppText(
                                          text: "Schedule Name",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FusionTextField(
                                          controller: viewModel.name,
                                          hintText: "Enter schedule name",
                                          decoration: InputDecoration(
                                            hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                                            counterText: '',
                                            fillColor: context.colorScheme.elevation2,
                                            filled: true,
                                            border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          ),
                                          onChanged: (String value) {},
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(child: Container()),
                                ],
                              ),

                              /// Color Picker Placeholder
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FusionAppText(
                                    text: "Color",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  /// Color Grid
                                  SizedBox(
                                    width: 400,
                                    child: SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_color_grid"),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 20,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: Zone.zoneColors.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final String hexCode = Zone.zoneColors[index];
                                          final Color color = hexToColor(hexCode);
                                          final bool isSelected = viewModel.color == hexCode;

                                          return SemanticHelper.container(
                                            testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_form_color_option_$index"),
                                            child: GestureDetector(
                                              onTap: () {
                                                viewModel.color = hexCode;
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border:
                                                      isSelected
                                                          ? Border.all(
                                                            color: context.colorScheme.primaryBlack,
                                                            width: 2,
                                                          )
                                                          : null,
                                                ),
                                                child:
                                                    isSelected
                                                        ? SemanticHelper.button(
                                                          testId: SemanticHelper.createTestId(
                                                            SemanticTypes.button,
                                                            "scheduler_form_color_selected_icon_$index",
                                                          ),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: context.colorScheme.primaryBlack.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Icon(
                                                              Icons.check,
                                                              color: Colors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        )
                                                        : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: <Widget>[
                                  FusionAppText(text: "Recurrence", style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  RadioGroup<RecurrenceType>(
                                    groupValue: viewModel.recurrenceType,
                                    onChanged: (RecurrenceType? selected) {
                                      if (selected != null) {
                                        viewModel.recurrenceType = selected;
                                      }
                                    },
                                    child: Row(
                                      children: <Widget>[
                                        for (final RecurrenceType type in RecurrenceType.values)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12.0),
                                            child: Row(
                                              children: <Widget>[
                                                Radio<RecurrenceType>(
                                                  value: type,
                                                  fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) => context.colorScheme.iconWhite),
                                                ),
                                                Text(
                                                  type.label,
                                                  style: context.textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // FusionSegmentedButton<RecurrenceType>(
                                  //   value: viewModel.recurrenceType,
                                  //   labels: <RecurrenceType, String>{
                                  //     RecurrenceType.none: RecurrenceType.none.label,
                                  //     RecurrenceType.daily: RecurrenceType.daily.label,
                                  //     RecurrenceType.weekly: RecurrenceType.weekly.label,
                                  //   },
                                  //   onChanged: (RecurrenceType value) {
                                  //     viewModel.recurrenceType = value;
                                  //   },
                                  // ),
                                ],
                              ),
                              // FusionAppText(
                              //   text: "Select Date Range",
                              //   style: context.textTheme.bodySmall?.copyWith(
                              //     fontWeight: FontWeight.w500,
                              //   ),
                              // ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    _DatePickerField(
                                      label: "From",
                                      selectedDate: viewModel.startDate,
                                      onDateSelected: (DateTime date) {
                                        viewModel.startDate = date;
                                      },
                                      validator: (DateTime? date) {
                                        if (viewModel.startDate == null) {
                                          return "Please select a start date";
                                        }
                                        return null;
                                      },
                                    ),
                                    if (viewModel.recurrenceType != RecurrenceType.none) ...<Widget>[
                                      const SizedBox(width: 12),
                                      _DatePickerField(
                                        validator: (DateTime? value) {
                                          if (viewModel.endDate == null) {
                                            return null;
                                          }
                                          if (viewModel.startDate != null && viewModel.endDate!.isBefore(viewModel.startDate!)) {
                                            return "End date cannot be before start date";
                                          }
                                          return null;
                                        },
                                        label: "To",
                                        selectedDate: viewModel.endDate,
                                        minDate: viewModel.startDate,
                                        onDateSelected: (DateTime date) {
                                          viewModel.endDate = date;
                                        },
                                      ),
                                    ],
                                    const SizedBox(width: 12),
                                    _TimePicker(
                                      title: "Start",
                                      time: viewModel.startTime,
                                      onChanged: (TimeOfDay value) {
                                        viewModel.startTime = value;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                child: switch (viewModel.recurrenceType) {
                                  RecurrenceType.weekly => const _WeeklyDaySelection(),
                                  _ => const SizedBox(),
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  FusionOutlinedButton(
                                    textStyle: context.textTheme.bodySmall,

                                    label: "Cancel",
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  FusionButton(
                                    label: "Done",
                                    isActive: viewModel.canEnableSubmit,
                                    textStyle: context.textTheme.bodySmall?.copyWith(
                                      color: viewModel.canEnableSubmit ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite.withAlpha(120),
                                    ),
                                    onTap: () async {
                                      try {
                                        final bool value = await viewModel.submit(initial);
                                        if (value) {
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        FusionToast.error(context, message: e.toString());
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                              // const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, SchedulerViewmodel viewModel, {ScheduleConfig? initial}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchedulerForm(viewModel: viewModel, initial: initial);
      },
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.title,
    required this.time,
    this.onChanged,
  });
  final String title;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isAM = time.period == DayPeriod.am;
    final Color borderColor = context.colorScheme.elevation4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: title,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.hardEdge,
          height: 40,
          child: Row(
            children: <Widget>[
              InkWell(
                onTap: () async {
                  final TimeOfDay? changed = await showTimePicker(context: context, initialTime: time);
                  if (changed != null && onChanged != null) {
                    onChanged!(changed);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: FusionAppText(
                      text: '${(time.hourOfPeriod).toString().padLeft(2, '0')}  :  ${time.minute.toString().padLeft(2, '0')}',
                      style: context.textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final TimeOfDay newTime = TimeOfDay(
                            hour: isAM ? time.hour : (time.hour - 12) % 24,
                            minute: time.minute,
                          );
                          if (onChanged != null) {
                            onChanged!(newTime);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isAM ? Colors.transparent : context.colorScheme.primaryBlack,
                            border: Border(
                              left: BorderSide(color: borderColor),
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "AM",
                              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final TimeOfDay newTime = TimeOfDay(
                            hour: isAM ? (time.hour + 12) % 24 : time.hour,
                            minute: time.minute,
                          );
                          if (onChanged != null) {
                            onChanged!(newTime);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: borderColor)),
                            color: !isAM ? context.colorScheme.primaryBlack : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              "PM",
                              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyDaySelection extends StatelessWidget {
  const _WeeklyDaySelection();

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulerFormViewModel>(
      builder: (BuildContext context, SchedulerFormViewModel viewModel, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            FusionAppText(text: "On Days", style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            Row(
              spacing: 6,
              children: <Widget>[
                for (final RecurrenceDay day in RecurrenceDay.values)
                  Builder(
                    builder: (BuildContext context) {
                      final bool isSelected = viewModel.recurrenceDays.contains(day);
                      return Column(
                        children: <Widget>[
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              if (viewModel.recurrenceDays.contains(day)) {
                                viewModel.removeRecurrenceDay(day);
                              } else {
                                viewModel.addRecurrenceDay(day);
                              }
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: WidgetStateBorderSide.resolveWith(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return BorderSide(
                                    color: context.colorScheme.elevation4,
                                    width: 1,
                                  );
                                }
                                return BorderSide(
                                  color: context.colorScheme.elevation4,
                                  width: 1,
                                );
                              },
                            ),
                            activeColor: context.colorScheme.elevation2,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          Text(
                            day.name.substring(0, 3).toUpperCase(),
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({super.key, required this.label, this.selectedDate, this.onDateSelected, this.minDate, this.validator});
  final String label;
  final DateTime? selectedDate;
  final DateTime? minDate;
  final ValueChanged<DateTime>? onDateSelected;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: validator,
      initialValue: selectedDate,
      builder: (FormFieldState<DateTime> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              text: label,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: state.hasError ? Colors.red : context.colorScheme.elevation4),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.hardEdge,
              height: 40,
              child: PopupMenuButton<dynamic>(
                position: PopupMenuPosition.under,
                tooltip: 'Select Date',
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<dynamic>>[
                      PopupMenuItem<dynamic>(
                        enabled: false,
                        padding: const EdgeInsets.all(0),
                        child: SizedBox(
                          width: 600,
                          child: CalendarDatePicker2(
                            // key: ValueKey<RecurrenceType>(viewModel.recurrenceType),
                            config: CalendarDatePicker2Config(
                              calendarType: CalendarDatePicker2Type.single,

                              selectedDayHighlightColor: Colors.black,
                              daySplashColor: Colors.black12,
                              firstDate: minDate ?? DateTime.now(), //.subtract(const Duration(hours: 24)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            ),
                            displayedMonthDate: selectedDate,
                            value: <DateTime?>[selectedDate],
                            onValueChanged: (List<DateTime> dates) {
                              if (dates.isNotEmpty && onDateSelected != null) {
                                onDateSelected!(dates.first);
                                Navigator.of(context).pop();
                              }
                              // if (viewModel.recurrenceType == RecurrenceType.none && dates.isNotEmpty) {
                              //   viewModel.startDate = dates.first;
                              //   viewModel.endDate = dates.first;
                              //   return;
                              // }
                              // if (dates.length >= 2) {
                              //   viewModel.startDate = dates.first;
                              //   viewModel.endDate = dates.last;
                              // }
                            },
                          ),
                        ),
                      ),
                    ],
                child: Container(
                  alignment: Alignment.center,
                  // constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 18,
                    children: <Widget>[
                      Text(
                        selectedDate != null ? DateFormat('dd-MM-yyyy').format(selectedDate!) : "Select Date",
                        style: context.textTheme.bodySmall,
                      ),
                      Icon(Icons.calendar_month, size: 16, color: context.colorScheme.iconWhite),
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                state.errorText!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
