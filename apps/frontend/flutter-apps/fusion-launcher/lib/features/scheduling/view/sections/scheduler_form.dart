import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:provider/provider.dart';

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

                          const SizedBox(height: 18),

                          /// Color Picker Placeholder
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
                            height: 90,
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

                          const SizedBox(height: 24),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: "Select Date Range",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    RangeDatePicker(
                                      centerLeadingDate: true,

                                      minDate: DateTime.now(),
                                      maxDate: DateTime.now().add(const Duration(days: 365)),

                                      selectedCellsDecoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                      ),
                                      singleSelectedCellDecoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                      currentDateDecoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        shape: BoxShape.circle,
                                      ),

                                      enabledCellsTextStyle: context.textTheme.bodySmall!,
                                      selectedCellsTextStyle: context.textTheme.bodySmall,
                                      currentDateTextStyle: context.textTheme.bodySmall,
                                      disabledCellsTextStyle: context.textTheme.bodySmall!.copyWith(color: Colors.grey),
                                      leadingDateTextStyle: context.textTheme.bodyMedium,
                                      singleSelectedCellTextStyle: context.textTheme.bodySmall!.copyWith(color: Colors.white),
                                      daysOfTheWeekTextStyle: context.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                      onRangeSelected: (DateTimeRange<DateTime> value) {
                                        viewModel.startDate = value.start;
                                        viewModel.endDate = value.end;
                                        print('value selected: ${value.start} - ${value.end}');
                                        // Handle selected range
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: <Widget>[
                                    _TimePicker(
                                      title: "Start",
                                      time: TimeOfDay(hour: 13, minute: 0),
                                    ),
                                    SizedBox(height: 50, child: Icon(Icons.arrow_forward)),
                                    _TimePicker(
                                      title: "End",
                                      time: TimeOfDay(hour: 13, minute: 0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    super.key,
    required this.title,
    required this.time,
  });
  final String title;
  final TimeOfDay time;
  @override
  Widget build(BuildContext context) {
    final bool isAM = time.period == DayPeriod.am;
    final Color borderColor = Colors.grey.shade400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(text: title),
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
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: FusionAppText(
                      text: '${(time.hour).toString().padLeft(2, '0')}  :  ${time.minute.toString().padLeft(2, '0')}',
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
                    Expanded(
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
