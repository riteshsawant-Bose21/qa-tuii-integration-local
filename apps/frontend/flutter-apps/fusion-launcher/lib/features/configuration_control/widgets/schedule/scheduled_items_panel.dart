import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/schedule_tab_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Left panel — SCHEDULED ITEMS.
///
/// Contains:
///  • "Show upcoming items" checkbox
///  • Show none / Show all / Show selected radio buttons
///  • Scheduler checklist (only when "Show selected" is active)
class ScheduledItemsPanel extends StatelessWidget {
  const ScheduledItemsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleTabCubit, ScheduleTabState>(
      builder: (BuildContext context, ScheduleTabState state) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PanelSectionHeader(title: 'SCHEDULED ITEMS'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: <Widget>[
                    // ── Show upcoming items checkbox ─────────────────────
                    _CheckboxRow(
                      label: 'Show upcoming items',
                      isChecked: state.showUpcoming,
                      onTap: () => context.read<ScheduleTabCubit>().toggleShowUpcoming(),
                    ),

                    const SizedBox(height: 8),

                    // ── Filter mode radio buttons ────────────────────────
                    _RadioRow(
                      label: 'Show none',
                      isSelected: state.filterMode == ScheduleFilterMode.none,
                      onTap: () => context.read<ScheduleTabCubit>().setFilterMode(ScheduleFilterMode.none),
                    ),
                    _RadioRow(
                      label: 'Show all',
                      isSelected: state.filterMode == ScheduleFilterMode.all,
                      onTap: () => context.read<ScheduleTabCubit>().setFilterMode(ScheduleFilterMode.all),
                    ),
                    _RadioRow(
                      label: 'Show selected',
                      isSelected: state.filterMode == ScheduleFilterMode.selected,
                      onTap: () => context.read<ScheduleTabCubit>().setFilterMode(ScheduleFilterMode.selected),
                    ),

                    // ── Schedule checklist (only for "Show selected") ────
                    if (state.filterMode == ScheduleFilterMode.selected) ...<Widget>[
                      const SizedBox(height: 4),
                      ...state.allSchedules.map((ScheduleConfig schedule) {
                        final bool isChecked = state.selectedScheduleIds.contains(schedule.id);
                        return _ScheduleCheckboxRow(
                          schedule: schedule,
                          isChecked: isChecked,
                          onToggle: () => context.read<ScheduleTabCubit>().toggleScheduleSelection(schedule.id),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Show upcoming items checkbox row ────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const _CheckboxRow({
    required this.label,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            _FusionCheckbox(isChecked: isChecked),
            const SizedBox(width: 10),
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Radio row ────────────────────────────────────────────────────────────────

class _RadioRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            _RadioIndicator(isSelected: isSelected),
            const SizedBox(width: 10),
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule checkbox row (indented, for "Show selected" mode) ───────────────

class _ScheduleCheckboxRow extends StatelessWidget {
  final ScheduleConfig schedule;
  final bool isChecked;
  final VoidCallback onToggle;

  const _ScheduleCheckboxRow({
    required this.schedule,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 6, 12, 6),
        child: Row(
          children: <Widget>[
            _FusionCheckbox(isChecked: isChecked),
            const SizedBox(width: 10),
            FusionAppText(
              text: schedule.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isChecked ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _FusionCheckbox extends StatelessWidget {
  final bool isChecked;
  const _FusionCheckbox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isChecked ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
        color: isChecked ? context.colorScheme.primaryColor : Colors.transparent,
      ),
      child: isChecked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
      ),
      child:
          isSelected
              ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.primaryColor,
                  ),
                ),
              )
              : null,
    );
  }
}
