part of '../scheduling_page.dart';

class _SchedulerSection extends StatelessWidget {
  const _SchedulerSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulerViewmodel, SchedulerState>(
      builder: (BuildContext context, SchedulerState state) {
        if (state.schedules.isEmpty) {
          return Center(
            child: Text(
              "No schedules added yet. Click on Create to add a new schedule.",
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          );
        }
        return FusionTable(
          spacing: 20,
          headers: <FusionTableHeader>[
            FusionTableHeader(title: "Name", flex: 3),
            FusionTableHeader(title: "Occurrence", flex: 2),
            FusionTableHeader(title: "", flex: 4),
            FusionTableHeader(title: "Time", flex: 2),
            FusionTableHeader(title: "Status", flex: 1),
            FusionTableHeader(title: "", flex: 1),
            FusionTableHeader(title: "", flex: 1),
            FusionTableHeader(title: "", flex: 1),
          ],
          itemCount: state.schedules.length,
          onRowTap: (int value) {
            final ScheduleConfig schedule = state.schedules[value];
            SchedulerForm.show(context, context.read<SchedulerViewmodel>(), initial: schedule);
          },
          itemBuilder: (BuildContext context, int index) {
            final ScheduleConfig schedule = state.schedules[index];
            return <Widget>[
              Text(schedule.name),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(schedule.recurrence.label)),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
              Column(
                spacing: 10,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: DateFormat("MMM dd, yyyy").format(schedule.startDate)),
                        if (schedule.recurrence != RecurrenceType.none) ...<InlineSpan>[
                          const TextSpan(text: " - "),
                          TextSpan(text: DateFormat("MMM dd, yyyy").format(schedule.endDate)),
                        ],
                      ],
                    ),
                  ),
                  if (RecurrenceType.weekly == schedule.recurrence)
                    Row(
                      children: <Widget>[
                        ...RecurrenceDay.values.map(
                          (RecurrenceDay e) => Expanded(
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  schedule.weeklyDays.contains(e.value) ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: schedule.weeklyDays.contains(e.value) ? Colors.black : Colors.grey,
                                  // size: 16,
                                ),
                                Text(
                                  e.name.substring(0, 3).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text("${schedule.time.hour.toString().padLeft(2, '0')}:${schedule.time.minute.toString().padLeft(2, '0')}")),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: schedule.status ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              FusionButton(label: "Test", onTap: () {}),
              InkWell(
                onTap: () {
                  /// Check if an event already exists for this schedule
                  final FusionEvent? eventsForScheduler = serviceLocator<ProjectViewModel>().getEventsForSchedule(
                    scheduleId: schedule.id,
                  );
                  if (eventsForScheduler != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      /// Set the selected event ID to the existing event for this schedule
                      serviceLocator<ProjectViewModel>().setSelectedEventId(eventsForScheduler.id);
                    });
                  } else {
                    /// Add the event to the project
                    serviceLocator<ProjectViewModel>().addEventForSchedule(
                      scheduleId: schedule.id,
                    );
                  }

                  /// Navigate to Configuration tab (index 3)
                  projectTabBroadcastController.add(3);

                  /// Switch to Events sub-tab within Configuration
                  serviceLocator<ProjectViewModel>().setConfigurationMenuMode(
                    ConfigurationMenuMode.events,
                  );
                },
                child: Center(
                  child: SvgPicture.asset(
                    "assets/icons/scheduler/run.svg",
                    width: 25,
                    height: 25,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<SchedulerViewmodel>().removeSchedule(schedule);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.grey,
                ),
              ),
            ];
          },
        );
      },
    );
  }
}

class FusionTable extends StatelessWidget {
  const FusionTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 10,
    this.onRowTap,
  });
  final List<FusionTableHeader> headers;
  final int itemCount;
  final List<Widget> Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              spacing: spacing,
              children:
                  headers
                      .map(
                        (final FusionTableHeader e) => Expanded(
                          flex: e.flex,
                          child: Align(
                            alignment: e.aligment,
                            child: Text(
                              e.title,
                              style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int index) {
                  final List<Widget> rowItems = itemBuilder(context, index);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: index != itemCount - 1 ? BorderSide(color: Colors.grey.withOpacity(0.3), width: 1) : BorderSide.none,
                      ),
                    ),
                    child: InkWell(
                      onTap: onRowTap != null ? () => onRowTap!(index) : null,
                      child: Row(
                        spacing: spacing,
                        children: List<Widget>.generate(
                          headers.length,
                          (int i) => Expanded(
                            flex: headers[i].flex,
                            child: Align(alignment: headers[i].aligment, child: rowItems[i]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FusionTableHeader {
  final String title;
  final int flex;
  final Alignment aligment;

  FusionTableHeader({required this.title, required this.flex, this.aligment = Alignment.centerLeft});
}
