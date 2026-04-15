part of '../scheduling_page.dart';

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

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
              final bool canGoBack = state.visibleMonth.isAfter(cubit.maxBackableMonth);
              final bool canGoForward = state.visibleMonth.isBefore(cubit.maxForwardableMonth);

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
                            FusionAppButton(
                              semanticId: 'timeline_section_now_button',
                              width: 100,
                              height: 32,
                              text: "Now",
                              textstyle: context.textTheme.l1SemiBold,
                              showPrefixIcon: true,
                              prefixIcon: Icons.calendar_today,
                              color: context.colorScheme.elevation1,
                              onPressed: () => cubit.goToMonth(DateTime.now()),
                              style: FusionAppButtonStyle.primary,
                            ),
                            const SizedBox(width: 12),

                            // ── Previous month ───────────────────────────────
                            IconButton(
                              onPressed: canGoBack ? cubit.previousMonth : null,
                              icon: FusionIcon.icon(
                                semanticId: 'timeline_section_previous_button',
                                Icons.chevron_left_rounded,
                                color: canGoBack ? context.colorScheme.iconDefault : context.colorScheme.iconDefault.withAlpha(60),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // ── Month picker chip ────────────────────────────
                            FusionArrowPopup(
                              semanticId: 'timeline_month_picker',
                              content: Builder(
                                builder:
                                    (BuildContext ctx) => _MonthPickerGrid(
                                      selectedMonth: state.visibleMonth.month,
                                      selectedYear: state.visibleMonth.year,
                                      minDate: cubit.maxBackableMonth,
                                      maxDate: cubit.maxForwardableMonth,
                                      onSelected: (int month) {
                                        Navigator.of(ctx).pop();
                                        cubit.goToMonth(
                                          DateTime(state.visibleMonth.year, month),
                                        );
                                      },
                                    ),
                              ),
                              child: _HeaderChip(
                                label: DateFormat('MMMM').format(state.visibleMonth),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // ── Year picker chip ─────────────────────────────
                            FusionArrowPopup(
                              semanticId: 'timeline_year_picker',
                              content: Builder(
                                builder:
                                    (BuildContext ctx) => _YearPickerList(
                                      selectedYear: state.visibleMonth.year,
                                      minYear: cubit.maxBackableMonth.year,
                                      maxYear: 2050,
                                      onSelected: (int year) {
                                        Navigator.of(ctx).pop();
                                        DateTime target = DateTime(year, state.visibleMonth.month);
                                        if (target.isBefore(cubit.maxBackableMonth)) {
                                          target = cubit.maxBackableMonth;
                                        } else if (target.isAfter(cubit.maxForwardableMonth)) {
                                          target = cubit.maxForwardableMonth;
                                        }
                                        cubit.goToMonth(target);
                                      },
                                    ),
                              ),
                              child: _HeaderChip(
                                label: state.visibleMonth.year.toString(),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // ── Next month ───────────────────────────────────
                            IconButton(
                              onPressed: canGoForward ? cubit.nextMonth : null,
                              icon: FusionIcon.icon(
                                semanticId: 'timeline_section_next_button',
                                Icons.chevron_right_rounded,
                                color: canGoForward ? context.colorScheme.iconDefault : context.colorScheme.iconDefault.withAlpha(60),
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: context.colorScheme.strokeLight),
                    Expanded(
                      child: CalenderView(
                        viewingMonth: state.visibleMonth,
                        events: state.currentMonthEvents,
                        eventsByDate: state.eventsByDate,
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

class _HeaderChip extends StatelessWidget {
  final String label;

  const _HeaderChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FusionAppText(
            text: label,
            style: context.textTheme.b3Medium,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month picker – 4 × 3 grid of abbreviated month names
// ─────────────────────────────────────────────────────────────────────────────

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
            final DateTime candidate = DateTime(selectedYear, month);
            final bool isDisabled = candidate.isBefore(DateTime(minDate.year, minDate.month)) || candidate.isAfter(DateTime(maxDate.year, maxDate.month));
            final bool isSelected = month == selectedMonth;

            return GestureDetector(
              onTap: isDisabled ? null : () => onSelected(month),
              child: Container(
                width: 48,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? context.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FusionAppText(
                  text: _monthLabels[i],
                  style: context.textTheme.l1Medium.withColor(
                    isDisabled
                        ? context.colorScheme.textDisabled
                        : isSelected
                        ? Colors.white
                        : context.colorScheme.textBody,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year picker – scrollable vertical list of available years
// ─────────────────────────────────────────────────────────────────────────────

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

    return SizedBox(
      width: 110,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: years.length,
        itemBuilder: (BuildContext ctx, int index) {
          final int year = years[index];
          final bool isSelected = year == selectedYear;

          return GestureDetector(
            onTap: () => onSelected(year),
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? context.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FusionAppText(
                text: '$year',
                style: context.textTheme.l1Medium.withColor(
                  isSelected ? Colors.white : context.colorScheme.textBody,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
