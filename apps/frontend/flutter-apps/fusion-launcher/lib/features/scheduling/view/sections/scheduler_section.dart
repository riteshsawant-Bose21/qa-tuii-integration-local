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
        return FusionAppTable(
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
          onReorder: (int oldIndex, int newIndex) {
            context.read<SchedulerViewmodel>().reOrderSchedules(oldIndex, newIndex);
          },
          itemBuilder: (BuildContext context, int index) {
            final ScheduleConfig schedule = state.schedules[index];
            return <Widget>[
              /// Name
              Text(schedule.name),

              /// Occurrence
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.colorScheme.primaryWhite),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: schedule.recurrence.label,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),

              /// Dates
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  spacing: 8,
                  children: <Widget>[
                    Text.rich(
                      style: context.textTheme.bodySmall,
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(text: DateFormat("MMM dd, yyyy").format(schedule.startDate)),
                          if (schedule.recurrence != RecurrenceType.none && schedule.endDate != null) ...<InlineSpan>[
                            const TextSpan(text: " - "),
                            TextSpan(text: DateFormat("MMM dd, yyyy").format(schedule.endDate!)),
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
                                    size: 14,
                                    color: schedule.weeklyDays.contains(e.value) ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite,
                                    // size: 16,
                                  ),
                                  FusionAppText(
                                    text: e.name.substring(0, 3).toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.colorScheme.primaryWhite),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 32,
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
                  color: schedule.status ? Colors.grey : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              FusionButton(label: "Test",accessLabel: 'scheduler_test_button', onTap: () {}),
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "scheduler_run_button_$index"),
                child: InkWell(
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
                    // projectTabBroadcastController.add(3);

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
                      color: context.colorScheme.iconWhite,
                    ),
                  ),
                ),
              ),
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "scheduler_delete_button_$index"),
                child: IconButton(
                  onPressed: () {
                    context.read<SchedulerViewmodel>().removeSchedule(schedule);
                  },
                  icon: const Icon(
                    LucideIcons.trash200,
                    color: Colors.grey,
                  ),
                ),
              ),
            ];
          },
        );
      },
    );
  }
}

class FusionAppTable extends StatelessWidget {
  const FusionAppTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 10,
    this.onRowTap,
    this.onReorder,
    this.keyExtractor,
  });
  final List<FusionTableHeader> headers;
  final int itemCount;
  final List<Widget> Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final ValueChanged<int>? onRowTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final String Function(int index)? keyExtractor;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /// table headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1.withAlpha(120),
            border: Border(
              top: BorderSide(color: context.colorScheme.elevation2, width: 1),
              bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
            ),
          ),

          child: Row(
            spacing: spacing,
            children: <Widget>[
              Visibility(
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: false,
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: context.colorScheme.iconDefault,
                ),
              ),
              ...headers.map(
                (final FusionTableHeader e) => Expanded(
                  flex: e.flex,
                  child: Align(
                    alignment: e.aligment,
                    child: FusionAppText(
                      text: e.title,
                      style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.colorScheme.elevation1, width: 1),
              ),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: itemCount,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                onReorder?.call(oldIndex, newIndex);
              },
              buildDefaultDragHandles: false,
              itemBuilder: (BuildContext context, int index) {
                final List<Widget> rowItems = itemBuilder(context, index);
                final String key = keyExtractor != null ? keyExtractor!(index) : 'fusion_table_row_$index';
                return Container(
                  key: ValueKey<String>(key),
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),

                      // bottom: index != itemCount - 1 ? BorderSide(color: Colors.grey.withOpacity(0.3), width: 1) : BorderSide.none,
                    ),
                  ),
                  child: SemanticHelper.button(
                    testId: SemanticHelper.createTestId(SemanticTypes.button, "fusion_table_row_$index"),
                    child: InkWell(
                      onTap: onRowTap != null ? () => onRowTap!(index) : null,
                      child: Row(
                        spacing: spacing,
                        children: <Widget>[
                          ReorderableDragStartListener(
                            key: ValueKey<String>(key),
                            index: index,
                            child: Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: context.colorScheme.iconDefault,
                            ),
                          ),
                          ...List<Widget>.generate(
                            headers.length,
                            (int i) => Expanded(
                              flex: headers[i].flex,
                              child: Align(alignment: headers[i].aligment, child: rowItems[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FusionTableHeader {
  final String title;
  final int flex;
  final Alignment aligment;

  FusionTableHeader({required this.title, required this.flex, this.aligment = Alignment.centerLeft});
}
