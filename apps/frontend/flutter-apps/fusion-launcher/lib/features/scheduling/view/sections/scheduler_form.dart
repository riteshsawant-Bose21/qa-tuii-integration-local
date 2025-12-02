import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../model/schedule_model.dart';
import '../../viewmodel/scheduler_form_viewmodel.dart';

class SchedulerForm extends StatelessWidget {
  const SchedulerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
      child: ChangeNotifierProvider<SchedulerFormViewModel>(
        create: (BuildContext context) => SchedulerFormViewModel(),
        child: Material(
          child: Column(
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
              Consumer<SchedulerFormViewModel>(
                builder: (BuildContext context, SchedulerFormViewModel viewModel, Widget? child) {
                  return Padding(
                    padding: const EdgeInsets.all(15.0),
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
                              SegmentedButton<RecurrenceType>(
                                value: viewModel.recurrenceType,
                                labels: const <RecurrenceType, String>{
                                  RecurrenceType.none: "Once",
                                  RecurrenceType.daily: "Daily",
                                  RecurrenceType.weekly: "Weekly",
                                },
                                onChanged: (RecurrenceType value) {
                                  viewModel.recurrenceType = value;
                                },
                              ),
                            ],
                          ),

                          Row(
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
                                    CalendarDatePicker2(
                                      // key: ValueKey<RecurrenceType>(viewModel.recurrenceType),
                                      config: CalendarDatePicker2Config(
                                        calendarType:
                                            viewModel.recurrenceType == RecurrenceType.none ? CalendarDatePicker2Type.single : CalendarDatePicker2Type.range,

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
                                        } else {
                                          // viewModel.startDate = dates.first;
                                          // viewModel.endDate = dates.first;
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SchedulerForm();
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
  const _WeeklyDaySelection({super.key});

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

class SegmentedButton<T> extends StatelessWidget {
  const SegmentedButton({super.key, required this.value, required this.labels, required this.onChanged});
  final T value;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final List<T> keys = labels.keys.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < keys.length; i++)
          GestureDetector(
            onTap: () {
              onChanged(keys[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: keys[i] == value ? Colors.black : Colors.transparent,
                border: const Border.symmetric(horizontal: BorderSide(color: Colors.grey, width: 1), vertical: BorderSide(color: Colors.grey, width: 0.5)),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(20) : Radius.zero,
                  right: i == keys.length - 1 ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                labels[keys[i]]!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: keys[i] == value ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthlyDaySelection extends StatelessWidget {
  const _MonthlyDaySelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulerFormViewModel>(
      builder: (BuildContext context, SchedulerFormViewModel viewModel, Widget? child) {
        return Row(
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
        );
      },
    );
  }
}
