import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/schedule_tab_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';

/// Right panel — VIRTUAL CONTROLLER (schedule tab).
///
/// Shows an "Events" card with:
///  • Scheduled tab (always visible)
///  • Upcoming tab (only when "Show upcoming items" is checked)
class ScheduleVcPanel extends StatefulWidget {
  const ScheduleVcPanel({super.key});

  @override
  State<ScheduleVcPanel> createState() => _ScheduleVcPanelState();
}

class _ScheduleVcPanelState extends State<ScheduleVcPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleTabCubit, ScheduleTabState>(
      builder: (BuildContext context, ScheduleTabState tabState) {
        return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
          builder: (BuildContext context, ConfigurationControlState ctrlState) {
            final String controllerName = ctrlState is ConfigControlLoaded ? (ctrlState.selectedController?.name ?? '') : '';

            // Ensure tab index is valid when upcoming tab is hidden
            final bool showUpcoming = tabState.showUpcoming;
            if (!showUpcoming && _tabController.index == 1) {
              _tabController.animateTo(0);
            }

            final List<ScheduleConfig> scheduledItems = tabState.scheduledItems;
            final List<ScheduleConfig> upcomingItems = tabState.upcomingItems;

            return Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorScheme.strokeLight, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ── "Events" header ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: FusionAppText(
                            text: 'Events',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.textPrimary,
                            ),
                          ),
                        ),

                        // ── Tab bar ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _EventsTabBar(
                            controller: _tabController,
                            showUpcoming: showUpcoming,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Tab content ────────────────────────────────
                        Expanded(
                          child:
                              showUpcoming
                                  ? TabBarView(
                                    controller: _tabController,
                                    children: <Widget>[
                                      _EventList(
                                        schedules: scheduledItems,
                                        controllerName: controllerName,
                                        emptyMessage: tabState.filterMode == ScheduleFilterMode.none ? 'No items to display' : 'No scheduled items',
                                        onToggle: (ScheduleConfig s) => context.read<ScheduleTabCubit>().toggleScheduleStatus(s),
                                      ),
                                      _EventList(
                                        schedules: upcomingItems,
                                        controllerName: controllerName,
                                        emptyMessage: 'No upcoming items',
                                        onToggle: (ScheduleConfig s) => context.read<ScheduleTabCubit>().toggleScheduleStatus(s),
                                      ),
                                    ],
                                  )
                                  // Single-tab mode: show only scheduled
                                  : _EventList(
                                    schedules: scheduledItems,
                                    controllerName: controllerName,
                                    emptyMessage: tabState.filterMode == ScheduleFilterMode.none ? 'No items to display' : 'No scheduled items',
                                    onToggle: (ScheduleConfig s) => context.read<ScheduleTabCubit>().toggleScheduleStatus(s),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _EventsTabBar extends StatelessWidget {
  final TabController controller;
  final bool showUpcoming;

  const _EventsTabBar({
    required this.controller,
    required this.showUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    if (!showUpcoming) {
      // Single pill — no real tab controller involved
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: context.colorScheme.elevation3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          alignment: Alignment.center,
          child: FusionAppText(
            text: 'Scheduled',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.colorScheme.strokeLight, width: 1),
        ),
        labelColor: context.colorScheme.textPrimary,
        unselectedLabelColor: context.colorScheme.textSecondary,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        tabs: const <Widget>[Tab(text: 'Scheduled'), Tab(text: 'Upcoming')],
      ),
    );
  }
}

// ─── Event list ───────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<ScheduleConfig> schedules;
  final String controllerName;
  final String emptyMessage;
  final void Function(ScheduleConfig) onToggle;

  const _EventList({
    required this.schedules,
    required this.controllerName,
    required this.emptyMessage,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FusionAppText(
            text: emptyMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: schedules.length,
      itemBuilder: (BuildContext context, int index) {
        final ScheduleConfig schedule = schedules[index];
        return _EventItem(
          schedule: schedule,
          subtitle: controllerName,
          onToggle: () => onToggle(schedule),
        );
      },
    );
  }
}

// ─── Single event item ────────────────────────────────────────────────────────

class _EventItem extends StatelessWidget {
  final ScheduleConfig schedule;
  final String subtitle;
  final VoidCallback onToggle;

  const _EventItem({
    required this.schedule,
    required this.subtitle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color stripColor = _parseColor(schedule.colorHex);
    final String timeStr = DateFormat('hh:mm').format(schedule.time);
    final String amPm = schedule.time.hour >= 12 ? 'PM' : 'AM';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          // ── Colored left strip ───────────────────────────────────
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Time ─────────────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FusionAppText(
                text: timeStr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: context.colorScheme.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  FusionAppText(
                    text: amPm,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Title + subtitle ─────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FusionAppText(
                  text: schedule.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  FusionAppText(
                    text: subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // ── Toggle switch ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: onToggle,
              child: _ToggleSwitch(isOn: schedule.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final String h = hex.startsWith('#') ? hex.substring(1) : hex;
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.teal;
  }
}

// ─── Toggle switch ────────────────────────────────────────────────────────────

class _ToggleSwitch extends StatelessWidget {
  final bool isOn;
  const _ToggleSwitch({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isOn ? context.colorScheme.primaryColor : context.colorScheme.elevation1,
        border: Border.all(
          color: isOn ? context.colorScheme.primaryColor : context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
