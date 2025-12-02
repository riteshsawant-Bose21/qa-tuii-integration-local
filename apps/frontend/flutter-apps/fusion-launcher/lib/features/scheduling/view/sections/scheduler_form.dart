import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/fusion_segmented_button.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/scheduler_form_viewmodel.dart';
import '../../viewmodel/scheduler_viewmodel.dart';

class SchedulerForm extends StatelessWidget {
  const SchedulerForm({super.key, required this.viewModel});
  final SchedulerViewmodel viewModel;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
      child: ChangeNotifierProvider<SchedulerFormViewModel>(
        create: (BuildContext context) => SchedulerFormViewModel(viewModel: viewModel),
        child: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const SizedBox(
                      width: 10,
                    ),
                    Text("Create Schedule", style: context.textTheme.titleMedium?.copyWith(color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer<SchedulerFormViewModel>(
                  builder: (BuildContext context, SchedulerFormViewModel viewModel, Widget? child) {
                    return Padding(
                      padding: const EdgeInsets.all(15.0),
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
                                        FusionTextField(
                                          controller: viewModel.name,
                                          hintText: "Enter schedule name",
                                          decoration: FusionInputDecoration.fusionDense(
                                            colorScheme: Theme.of(context).colorScheme,
                                            hintText: 'Enter schedule name',
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

                                        return GestureDetector(
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
                                                        color: Theme.of(context).colorScheme.greyDark,
                                                        width: 2,
                                                      )
                                                      : null,
                                            ),
                                            child:
                                                isSelected
                                                    ? Container(
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.greyDark.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: <Widget>[
                                  FusionAppText(text: "Recurrence", style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  FusionSegmentedButton<RecurrenceType>(
                                    value: viewModel.recurrenceType,
                                    labels: <RecurrenceType, String>{
                                      RecurrenceType.none: RecurrenceType.none.label,
                                      RecurrenceType.daily: RecurrenceType.daily.label,
                                      RecurrenceType.weekly: RecurrenceType.weekly.label,
                                    },
                                    onChanged: (RecurrenceType value) {
                                      viewModel.recurrenceType = value;
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(
                                height: 400,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          FusionAppText(
                                            text: "Select Date Range",
                                            style: context.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          FormField<DateTime>(
                                            validator: (DateTime? value) {
                                              if (viewModel.startDate == null) {
                                                return "Please select a start date";
                                              }
                                              if (viewModel.recurrenceType != RecurrenceType.none &&
                                                  (viewModel.endDate == null || viewModel.endDate!.isBefore(viewModel.startDate!))) {
                                                return "Please select a valid end date";
                                              }
                                              return null;
                                            },
                                            builder: (FormFieldState<dynamic> field) {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: field.hasError ? Colors.red : Colors.transparent),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: CalendarDatePicker2(
                                                      // key: ValueKey<RecurrenceType>(viewModel.recurrenceType),
                                                      config: CalendarDatePicker2Config(
                                                        calendarType:
                                                            viewModel.recurrenceType == RecurrenceType.none
                                                                ? CalendarDatePicker2Type.single
                                                                : CalendarDatePicker2Type.range,

                                                        selectedDayHighlightColor: Colors.black,
                                                        daySplashColor: Colors.black12,
                                                        firstDate: DateTime.now(), //.subtract(const Duration(hours: 24)),
                                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                                      ),
                                                      value:
                                                          viewModel.recurrenceType == RecurrenceType.none
                                                              ? <DateTime?>[viewModel.startDate]
                                                              : <DateTime?>[viewModel.startDate, viewModel.endDate],
                                                      onValueChanged: (List<DateTime> dates) {
                                                        if (viewModel.recurrenceType == RecurrenceType.none && dates.isNotEmpty) {
                                                          viewModel.startDate = dates.first;
                                                          viewModel.endDate = dates.first;
                                                          return;
                                                        }
                                                        if (dates.length >= 2) {
                                                          viewModel.startDate = dates.first;
                                                          viewModel.endDate = dates.last;
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  if (field.hasError)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        field.errorText!,
                                                        style: TextStyle(
                                                          color: Colors.red.shade700,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Column(
                                            children: <Widget>[
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                spacing: 10,
                                                children: <Widget>[
                                                  _TimePicker(
                                                    title: "Start",
                                                    time: viewModel.startTime,
                                                    onChanged: (TimeOfDay value) {
                                                      viewModel.startTime = value;
                                                    },
                                                  ),
                                                  // const SizedBox(height: 50, child: Icon(Icons.arrow_forward)),
                                                  // _TimePicker(
                                                  //   title: "End",
                                                  //   time: viewModel.endTime,
                                                  //   onChanged: (TimeOfDay value) {
                                                  //     viewModel.endTime = value;
                                                  //   },
                                                  // ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              switch (viewModel.recurrenceType) {
                                                RecurrenceType.weekly => const _WeeklyDaySelection(),
                                                _ => const SizedBox(),
                                              },
                                            ],
                                          ),
                                          // const Spacer(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: <Widget>[
                                              FusionOutlinedButton(
                                                label: "Cancel",
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              const SizedBox(width: 12),
                                              FusionButton(
                                                label: "Done",
                                                isActive: viewModel.canEnableSubmit,
                                                onTap: () async {
                                                  try {
                                                    final bool value = await viewModel.submit();
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

  static Future<void> show(BuildContext context, SchedulerViewmodel viewModel) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchedulerForm(viewModel: viewModel);
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
    final Color borderColor = Colors.grey.shade400;
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
          height: 50,
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
                            color: isAM ? Colors.black : Colors.transparent,
                            border: Border(
                              left: BorderSide(color: borderColor),
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "AM",
                              style: context.textTheme.bodySmall?.copyWith(
                                color: isAM ? Colors.white : Colors.black,
                              ),
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
                            color: !isAM ? Colors.black : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              "PM",
                              style: context.textTheme.bodySmall?.copyWith(
                                color: !isAM ? Colors.white : Colors.black,
                              ),
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
              children: <Widget>[
                for (final RecurrenceDay day in RecurrenceDay.values)
                  Builder(
                    builder: (BuildContext context) {
                      final bool isSelected = viewModel.recurrenceDays.contains(day);
                      return Column(
                        children: <Widget>[
                          Checkbox(
                            activeColor: Colors.black,
                            value: isSelected,
                            onChanged: (_) {
                              if (viewModel.recurrenceDays.contains(day)) {
                                viewModel.removeRecurrenceDay(day);
                              } else {
                                viewModel.addRecurrenceDay(day);
                              }
                            },
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
