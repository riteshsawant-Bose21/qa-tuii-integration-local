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
              return SemanticHelper.button(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.button,
                  "timeline_section",
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "timeline_section_header"),
                        child: Row(
                          children: <Widget>[
                            FusionAppText(
                              semanticId: 'timeline_section_header_date',
                              text: DateFormat(
                                "MMMM yyyy",
                              ).format(state.visibleMonth),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium,
                            ),
                            const Spacer(),

                            FusionTextButton(
                              accessLabel: 'timeline_section_now_button',
                              width: 100,
                              height: 32,
                              label: "Now",
                              backgroundColor: context.colorScheme.elevation3,
                              onTap: () {
                                BlocProvider.of<TimelineCubit>(
                                  context,
                                ).goToMonth(DateTime.now());
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                BlocProvider.of<TimelineCubit>(
                                  context,
                                ).previousMonth();
                              },
                              icon: FusionIcon.icon(semanticId: 'timeline_section_previous_button', Icons.chevron_left_rounded),
                            ),
                            IconButton(
                              onPressed: () {
                                BlocProvider.of<TimelineCubit>(context).nextMonth();
                              },
                              icon: FusionIcon.icon(semanticId: 'timeline_section_next_button', Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
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
