part of '../scheduling_page.dart';

// Returns the Sunday that starts the ISO week containing [date].
DateTime _weekStart(DateTime date) {
  final int offset = date.weekday % 7; // Mon=1…Sun=7 → Sun=0
  return DateTime(date.year, date.month, date.day - offset);
}

// Formats a week range like "05 - 11 April 2026" or "28 April - 04 May 2026".
String _weekRangeLabel(DateTime weekStart) {
  final DateTime end = weekStart.add(const Duration(days: 6));
  if (weekStart.month == end.month) {
    // "05 - 11 April 2026"
    return '${DateFormat('dd').format(weekStart)} - ${DateFormat('dd MMMM yyyy').format(end)}';
  } else if (weekStart.year == end.year) {
    // "28 April - 04 May 2026"
    return '${DateFormat('dd MMMM').format(weekStart)} - ${DateFormat('dd MMMM yyyy').format(end)}';
  }
  // "29 Dec 2026 - 04 Jan 2027"
  return '${DateFormat('dd MMM yyyy').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(end)}';
}

// ─────────────────────────────────────────────────────────────────────────────

class _TimelineSection extends StatefulWidget {
  const _TimelineSection();

  @override
  State<_TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<_TimelineSection> {
  bool _isMonthView = true;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "timeline_section"),
      child: BlocProvider<TimelineCubit>(
        create:
            (BuildContext context) => TimelineCubit(
              BlocProvider.of<SchedulerViewmodel>(context).state.schedules,
            ),
        child: BlocListener<SchedulerViewmodel, SchedulerState>(
          bloc: BlocProvider.of<SchedulerViewmodel>(context),
          listener: (BuildContext context, SchedulerState state) {
            BlocProvider.of<TimelineCubit>(context).refresh(state.schedules);
          },
          child: BlocBuilder<TimelineCubit, TimelineState>(
            builder: (BuildContext context, TimelineState state) {
              final TimelineCubit cubit = BlocProvider.of<TimelineCubit>(context);

              // ── Mode-aware navigation guards ──────────────────────────────
              final DateTime ws = _weekStart(state.visibleMonth);
              final bool canGoBack = _isMonthView ? state.visibleMonth.isAfter(cubit.maxBackableMonth) : ws.isAfter(_weekStart(DateTime.now()));

              void prev() => _isMonthView ? cubit.previousMonth() : cubit.previousWeek();
              void next() => _isMonthView ? cubit.nextMonth() : cubit.nextWeek();

              return SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "timeline_section"),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "timeline_section_header"),
                        child: Row(
                          children: <Widget>[
                            // ── Now button ──────────────────────────────────
                            Material(
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => cubit.goToMonth(DateTime.now()),
                                hoverColor: context.colorScheme.strokeLight,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      FusionIcon.icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        semanticId: "timeline_section_now_button_icon",
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      FusionAppText(
                                        text: "Today",
                                        style: context.textTheme.l1SemiBold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ── Previous ─────────────────────────────────────
                            IconButton(
                              hoverColor: context.colorScheme.strokeLight,
                              onPressed: canGoBack ? prev : null,
                              icon: FusionIcon.icon(
                                semanticId: 'timeline_section_previous_button',
                                Icons.chevron_left_rounded,
                                color: canGoBack ? context.colorScheme.iconDefault : context.colorScheme.iconDefault.withAlpha(60),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // ── Month picker chip  (month view) ──────────────
                            // ── Week range label   (week view)  ──────────────
                            if (_isMonthView) ...<Widget>[
                              FusionArrowPopup(
                                semanticId: 'timeline_month_picker',
                                backgroundColor: context.colorScheme.elevation2,
                                content: Builder(
                                  builder:
                                      (BuildContext ctx) => _MonthPickerGrid(
                                        selectedMonth: state.visibleMonth.month,
                                        selectedYear: state.visibleMonth.year,
                                        minDate: cubit.maxBackableMonth,
                                        maxDate: cubit.maxForwardableMonth,
                                        onSelected: (int month) {
                                          Navigator.of(ctx).pop();
                                          cubit.goToMonth(DateTime(state.visibleMonth.year, month));
                                        },
                                      ),
                                ),
                                child: _HeaderChip(
                                  label: DateFormat('MMMM').format(state.visibleMonth),
                                ),
                              ),
                              const SizedBox(width: 4),
                              FusionArrowPopup(
                                semanticId: 'timeline_year_picker',
                                backgroundColor: context.colorScheme.elevation2,
                                content: Builder(
                                  builder:
                                      (BuildContext ctx) => _YearPickerList(
                                        selectedYear: state.visibleMonth.year,
                                        minYear: cubit.maxBackableMonth.year,
                                        maxYear: cubit.maxForwardableMonth.year,
                                        onSelected: (int year) {
                                          Navigator.of(ctx).pop();
                                          DateTime target = DateTime(year, state.visibleMonth.month);
                                          if (target.isBefore(cubit.maxBackableMonth)) {
                                            target = cubit.maxBackableMonth;
                                          }
                                          cubit.goToMonth(target);
                                        },
                                      ),
                                ),
                                child: _HeaderChip(
                                  label: state.visibleMonth.year.toString(),
                                ),
                              ),
                            ] else ...<Widget>[
                              SizedBox(
                                width: 220,
                                child: FusionAppText(
                                  maxLine: 1,
                                  textAlign: TextAlign.center,
                                  text: _weekRangeLabel(ws),
                                  style: context.textTheme.b3Medium,
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),

                            // ── Next ─────────────────────────────────────────
                            IconButton(
                              onPressed: next,
                              hoverColor: context.colorScheme.strokeLight,
                              icon: FusionIcon.icon(
                                semanticId: 'timeline_section_next_button',
                                Icons.chevron_right_rounded,
                                color: context.colorScheme.iconDefault,
                              ),
                            ),

                            const Spacer(),

                            // ── Month / Week toggle ───────────────────────────
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation2,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: <Widget>[
                                  ViewToggle(
                                    label: 'Month',
                                    isActive: _isMonthView,
                                    onTap: () => setState(() => _isMonthView = true),
                                  ),
                                  const SizedBox(width: 4),
                                  ViewToggle(
                                    label: 'Week',
                                    isActive: !_isMonthView,
                                    onTap: () => setState(() => _isMonthView = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: context.colorScheme.strokeLight),

                    // ── Body ─────────────────────────────────────────────────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            _isMonthView
                                ? CalenderView(
                                  key: const ValueKey<String>('month'),
                                  viewingMonth: state.visibleMonth,
                                  events: state.currentMonthEvents,
                                  eventsByDate: state.eventsByDate,
                                )
                                : _WeekView(
                                  key: const ValueKey<String>('week'),
                                  weekAnchor: state.visibleMonth,
                                  eventsByDate: state.eventsByDate,
                                ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final DateTime weekAnchor;
  final Map<DateTime, List<CalendarEvent>> eventsByDate;

  const _WeekView({super.key, required this.weekAnchor, required this.eventsByDate});

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime start = _weekStart(weekAnchor);
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int i) => start.add(Duration(days: i)),
    );

    return Column(
      children: <Widget>[
        WeekDayRowHeader(dates: days),
        const SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  days.map((DateTime day) {
                    final bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                    final DateTime key = DateTime(day.year, day.month, day.day);
                    final List<CalendarEvent> events = eventsByDate[key] ?? <CalendarEvent>[];

                    return Expanded(
                      child: Container(
                        // margin: EdgeInsets.only(right: isLast ? 0 : 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? context.colorScheme.primary : context.colorScheme.strokeLight,
                            width: 1,
                          ),
                        ),
                        child: _WeekDayColumn(
                          day: day,
                          isToday: isToday,
                          events: events,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekDayColumn extends StatefulWidget {
  final DateTime day;
  final bool isToday;
  final List<CalendarEvent> events;

  const _WeekDayColumn({
    required this.day,
    required this.isToday,
    required this.events,
  });

  @override
  State<_WeekDayColumn> createState() => _WeekDayColumnState();
}

class _WeekDayColumnState extends State<_WeekDayColumn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final bool isPast = DateTime(widget.day.year, widget.day.month, widget.day.day).isBefore(DateTime(today.year, today.month, today.day));
    final bool showAdd = _isHovered && !isPast;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            isPast
                ? null
                : () => SchedulerForm.show(
                  context,
                  context.read<SchedulerViewmodel>(),
                ),
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                // Events list
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 4),
                        ...widget.events.map(
                          (CalendarEvent event) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: EventCard(event: event),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── "Add Schedule" hover overlay (mirrors MonthDayCell) ─────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !showAdd,
                child: AnimatedOpacity(
                  opacity: showAdd ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap:
                        () => SchedulerForm.show(
                          context,
                          context.read<SchedulerViewmodel>(),
                        ),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.colorScheme.elevation3,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FusionIcon.icon(
                            semanticId: 'week_add_schedule_icon',
                            Icons.add,
                            size: 16,
                            color: context.colorScheme.iconDefault,
                          ),
                          const SizedBox(width: 6),
                          FusionAppText(
                            text: 'Add Schedule',
                            style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers below (ViewToggle, _HeaderChip, _MonthPickerGrid, _YearPickerList)
// ─────────────────────────────────────────────────────────────────────────────
class ViewToggle extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const ViewToggle({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<ViewToggle> createState() => _ViewToggleState();
}

class _ViewToggleState extends State<ViewToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (widget.isActive) {
      backgroundColor = context.colorScheme.elevation1;
    } else if (_isHovered) {
      backgroundColor = context.colorScheme.strokeLight;
    } else {
      backgroundColor = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isActive || _isHovered ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatefulWidget {
  final String label;

  const _HeaderChip({required this.label});

  @override
  State<_HeaderChip> createState() => _HeaderChipState();
}

class _HeaderChipState extends State<_HeaderChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovered ? context.colorScheme.strokeLight : context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.colorScheme.strokeLight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: widget.label,
                style: context.textTheme.b3Medium,
              ),
            ),
            const SizedBox(width: 4),
            FusionIcon.icon(
              semanticId: 'header_chip_chevron',
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: context.colorScheme.iconDefault,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerGrid extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueChanged<int> onSelected;

  const _MonthPickerGrid({
    required this.selectedMonth,
    required this.selectedYear,
    required this.minDate,
    required this.maxDate,
    required this.onSelected,
  });

  static const List<String> _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 220,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(12, (int i) {
            final int month = i + 1;
            // Only disable months in the minimum year that fall before the
            // allowed start month. All months in future years are always active.
            final bool isDisabled = selectedYear == minDate.year && month < minDate.month;
            final bool isSelected = month == selectedMonth;

            return _MonthChip(
              label: _monthLabels[i],
              isSelected: isSelected,
              isDisabled: isDisabled,
              onTap: isDisabled ? null : () => onSelected(month),
            );
          }),
        ),
      ),
    );
  }
}

class _MonthChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _MonthChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_MonthChip> createState() => _MonthChipState();
}

class _MonthChipState extends State<_MonthChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = context.colorScheme.primary;
    } else if (_isHovered && !widget.isDisabled) {
      backgroundColor = context.colorScheme.strokeLight;
    } else {
      backgroundColor = Colors.transparent;
    }

    Color textColor;
    if (widget.isDisabled) {
      textColor = context.colorScheme.textDisabled;
    } else if (widget.isSelected || (_isHovered && !widget.isDisabled)) {
      textColor = Colors.white;
    } else {
      textColor = context.colorScheme.textBody;
    }

    return MouseRegion(
      cursor: widget.isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FusionAppText(
            text: widget.label,
            style: context.textTheme.l1Medium.withColor(textColor),
          ),
        ),
      ),
    );
  }
}

class _YearPickerList extends StatelessWidget {
  final int selectedYear;
  final int minYear;
  final int maxYear;
  final ValueChanged<int> onSelected;

  const _YearPickerList({
    required this.selectedYear,
    required this.minYear,
    required this.maxYear,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> years = <int>[
      for (int y = minYear; y <= maxYear; y++) y,
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 220,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              years
                  .map(
                    (int year) => _YearChip(
                      year: year,
                      isSelected: year == selectedYear,
                      onTap: () => onSelected(year),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _YearChip extends StatefulWidget {
  final int year;
  final bool isSelected;
  final VoidCallback onTap;

  const _YearChip({
    required this.year,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_YearChip> createState() => _YearChipState();
}

class _YearChipState extends State<_YearChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = context.colorScheme.primary;
    } else if (_isHovered) {
      backgroundColor = context.colorScheme.strokeLight;
    } else {
      backgroundColor = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FusionAppText(
            text: '${widget.year}',
            style: context.textTheme.l1Medium.withColor(
              (widget.isSelected || _isHovered) ? Colors.white : context.colorScheme.textBody,
            ),
          ),
        ),
      ),
    );
  }
}
