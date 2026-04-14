part of '../scheduling_page.dart';

class _SchedulerSection extends StatelessWidget {
  const _SchedulerSection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_section"),
      child: BlocBuilder<SchedulerViewmodel, SchedulerState>(
        builder: (BuildContext context, SchedulerState state) {
          if (state.schedules.isEmpty) {
            return Center(
              child: FusionAppText(
                semanticId: 'scheduler_no_schedules_text',
                text: "No schedules added yet. Click on Create to add a new schedule.",
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            );
          }
          return FusionAppTable(
            semanticId: 'scheduler_table',
            spacing: 20,
            headers: <FusionTableHeader>[
              FusionTableHeader(title: "NAME", flex: 2, aligment: Alignment.centerLeft),
              FusionTableHeader(title: "OCCURRENCE", flex: 2, aligment: Alignment.centerLeft),
              FusionTableHeader(title: "DAY", flex: 6, aligment: Alignment.centerLeft),
              FusionTableHeader(title: "TIME", flex: 2, aligment: Alignment.center),
              FusionTableHeader(title: "DATE RANGE", flex: 2, aligment: Alignment.center),
              FusionTableHeader(title: "ACTIVE", flex: 2, aligment: Alignment.center),
              FusionTableHeader(title: "TEST", flex: 2, aligment: Alignment.center),
              FusionTableHeader(title: "PROGRAM EVENT", flex: 2, aligment: Alignment.center),
              FusionTableHeader(title: "", flex: 1, aligment: Alignment.center),
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
                FusionAppText(
                  semanticId: 'scheduler_table_data_name',
                  maxLine: 1,
                  text: schedule.name,
                  style: context.textTheme.l1Regular,
                ),

                /// Occurrence
                FusionAppText(
                  semanticId: 'scheduler_table_data_recurrence',
                  text: schedule.recurrence.label,
                  style: context.textTheme.l1Regular,
                ),

                /// day
                if (RecurrenceType.none == schedule.recurrence)
                  Text.rich(
                    style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        RecurrenceDay.values
                            .map(
                              (RecurrenceDay e) => Column(
                                spacing: 4,
                                children: <Widget>[
                                  Opacity(opacity: 0.3, child: FusionCheckbox(semanticId: "", onChanged: () {}, value: schedule.weeklyDays.contains(e.value))),
                                  FusionAppText(
                                    semanticId: 'scheduler_table_data_recurrence_day_text',
                                    text: e.name.substring(0, 3).toUpperCase(),
                                    style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),

                if (RecurrenceType.daily == schedule.recurrence)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        RecurrenceDay.values
                            .map(
                              (RecurrenceDay e) => Column(
                                spacing: 4,
                                children: <Widget>[
                                  Opacity(opacity: 0.3, child: FusionCheckbox(semanticId: "", onChanged: () {}, enabled: false, value: true)),
                                  FusionAppText(
                                    semanticId: 'scheduler_table_data_recurrence_day_text',
                                    text: e.name.substring(0, 3).toUpperCase(),
                                    style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),

                /// time
                FusionAppText(
                  semanticId: 'scheduler_table_data_time',
                  text: FusionUiUtils.formatTime12h(schedule.time),
                  style: context.textTheme.b3Regular.withColor(context.colorScheme.textBody),
                ),

                /// date range
                Opacity(
                  opacity: 0.3,
                  child: FusionCheckbox(
                    semanticId: 'scheduler_table_data_date_range_checkbox',
                    onChanged: () {},
                    value: schedule.endDate != null,
                  ),
                ),

                /// active check box
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, "scheduler_table_data_status_icon_$index"),
                  child: FusionSwitch(
                    height: 22,
                    width: 36,
                    value: schedule.status,
                    onChanged: (bool value) {
                      context.read<SchedulerViewmodel>().toggleScheduleStatus(schedule);
                    },
                  ),
                ),

                /// test
                FusionAppButton(
                  height: 32,
                  width: 72,
                  borderRadius: 8,
                  text: "Test",
                  style: FusionAppButtonStyle.primary,
                  semanticId: 'scheduler_test_button',
                  onPressed: () {},
                ),

                /// program event
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

                /// kebab menu for edit/delete
                FusionKebabPopup(
                  semanticId: 'scheduler_row_kebab_menu',
                  popupOffset: const Offset(-70, 4),
                  onEdit: () {
                    final ScheduleConfig schedule = state.schedules[index];
                    SchedulerForm.show(context, context.read<SchedulerViewmodel>(), initial: schedule);
                  },
                  onDelete: () {
                    context.read<SchedulerViewmodel>().removeSchedule(schedule);
                  },
                ),
              ];
            },
          );
        },
      ),
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
    this.semanticId,
  });
  final List<FusionTableHeader> headers;
  final int itemCount;
  final List<Widget> Function(BuildContext context, int index) itemBuilder;
  final double spacing;
  final ValueChanged<int>? onRowTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final String Function(int index)? keyExtractor;
  final String? semanticId;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /// table headers
        SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "fusion_table_header_$semanticId"),
          child: Container(
            margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              // color: context.colorScheme.elevation3,
              border: Border(
                top: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                left: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),

            child: Row(
              spacing: spacing,
              children: <Widget>[
                ...headers.map(
                  (final FusionTableHeader e) => Expanded(
                    flex: e.flex,
                    child: Align(
                      alignment: e.aligment,
                      child: FusionAppText(
                        semanticId: 'fusion_table_header_text',
                        text: e.title,
                        maxLine: 1,
                        style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// table rows
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
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
                return _FusionTableRow(
                  key: ValueKey<String>(key),
                  rowKey: key,
                  index: index,
                  itemCount: itemCount,
                  rowItems: rowItems,
                  headers: headers,
                  spacing: spacing,
                  onRowTap: onRowTap,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FusionTableRow extends StatefulWidget {
  const _FusionTableRow({
    super.key,
    required this.rowKey,
    required this.index,
    required this.itemCount,
    required this.rowItems,
    required this.headers,
    required this.spacing,
    required this.onRowTap,
  });

  final String rowKey;
  final int index;
  final int itemCount;
  final List<Widget> rowItems;
  final List<FusionTableHeader> headers;
  final double spacing;
  final ValueChanged<int>? onRowTap;

  @override
  State<_FusionTableRow> createState() => _FusionTableRowState();
}

class _FusionTableRowState extends State<_FusionTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _isHovered ? context.colorScheme.elevation2 : Colors.transparent,
          border: Border(
            bottom: widget.index != widget.itemCount - 1 ? BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1) : BorderSide.none,
          ),
        ),
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "fusion_table_row_${widget.index}"),
          child: ReorderableDragStartListener(
            key: ValueKey<String>(widget.rowKey),
            index: widget.index,
            child: InkWell(
              hoverColor: Colors.transparent,
              onTap: widget.onRowTap != null ? () => widget.onRowTap!(widget.index) : null,
              child: Row(
                spacing: widget.spacing,
                children: List<Widget>.generate(
                  widget.headers.length,
                  (int i) => Expanded(
                    flex: widget.headers[i].flex,
                    child: Align(alignment: widget.headers[i].aligment, child: widget.rowItems[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
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
