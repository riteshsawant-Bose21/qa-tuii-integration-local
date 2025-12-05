part of '../scheduling_page.dart';

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimelineCubit>(
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
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      FusionAppText(
                        text: DateFormat("MMMM yyyy").format(state.visibleMonth),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                      const Spacer(),

                      FusionTextButton(
                        width: 100,
                        label: "Now",
                        onTap: () {
                          BlocProvider.of<TimelineCubit>(context).goToMonth(DateTime.now());
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          BlocProvider.of<TimelineCubit>(context).previousMonth();
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        onPressed: () {
                          BlocProvider.of<TimelineCubit>(context).nextMonth();
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
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
            );
          },
        ),
      ),
    );
  }
}
