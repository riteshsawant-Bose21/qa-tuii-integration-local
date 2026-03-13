import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/configuration_widgets/action_drop_down.dart';
import 'package:fusion_lib/constants/fusion_constants.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/events/configation_events_keys.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';

import '../../viewModel/events_viewmodel/config_events_state.dart';
import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';

/// Event Trigger Row Header Widget
/// This widget displays the header row for event triggers, including dropdowns for selecting trigger type, item, action, condition, and value.
/// Example:
/// ```dart
/// EventTriggerRowHeader(eventId: 'event123')
/// ```
/// Parameters:
/// - [eventId]: The ID of the event for which the trigger row header is displayed
/// Returns:
/// - A [Widget] representing the event trigger row header

class EventTriggerRowHeader extends StatelessWidget {
  final String eventId;

  const EventTriggerRowHeader({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    // Wrap in BlocBuilder so all sub-widgets rebuild whenever the events state
    // changes (e.g. after selecting a trigger type / item / action).
    return BlocBuilder<ConfigEventsViewmodel, ConfigEventsState>(
      builder: (BuildContext context, ConfigEventsState state) {
        // Guard against the eventId becoming stale (event deleted / switched)
        // in the timing window before ConfigEventActionsViewmodel transitions away.
        final bool eventExists = state.events.any((FusionEvent e) => e.id == eventId);
        if (!eventExists) return const SizedBox.shrink();

        final ConfigEventsViewmodel cubit = context.read<ConfigEventsViewmodel>();


        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.eventtriggerrowheader),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: context.colorScheme.elevation2.withAlpha(120),
            child: Row(
              children: <Widget>[
                /// Trigger Type Dropdown
                _TriggerTypeDropdown(eventId: eventId, cubit: cubit),
                const SizedBox(width: 16),

                /// Trigger Item Dropdown
                _TriggerItemDropdown(eventId: eventId, configEventsViewmodel: cubit),
                const SizedBox(width: 16),

                /// Trigger Action Dropdown
                _ActionTypeDropdown(eventId: eventId, cubit: cubit),
                const SizedBox(width: 16),

                /// Trigger Condition Dropdown
                _ConditionDropdown(eventId: eventId, cubit: cubit),
                const SizedBox(width: 16),

                /// Value Column
                _ValueColumn(eventId: eventId, cubit: cubit),
              ],
            ),
          ),
        );
  }

class _TriggerTypeDropdown extends StatelessWidget {
  final String eventId;
  final ConfigEventsViewmodel cubit;
  const _TriggerTypeDropdown({required this.eventId, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = cubit.getEventById(eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: FusionTestKeys.instance.eventtriggerrowheadertype,
            text: "Trigger Type",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "event_trigger_type"),
            child: FusionDropdown<EventTriggerType>(
              value: selectedEvent.triggerType,
              hint: "Select Trigger Type",
              items: cubit.getEventTriggers(),
              display: (EventTriggerType e) => e.displayName,
              onChanged: (EventTriggerType? triggerType) {
                if (triggerType != null) {
                  cubit.updateEventTrigger(eventId: eventId, newTrigger: triggerType);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Item Dropdown
class _TriggerItemDropdown extends StatelessWidget {
  final String eventId;
  final ConfigEventsViewmodel configEventsViewmodel;

  const _TriggerItemDropdown({required this.eventId, required this.configEventsViewmodel});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = configEventsViewmodel.getEventById(eventId);
    final List<EventTriggerItemDropdown> availableItems =
        selectedEvent.triggerType != null
            ? configEventsViewmodel.getEventTriggerDropdownItems(triggerType: selectedEvent.triggerType!)
            : <EventTriggerItemDropdown>[];

    // Find the current value, ensuring it exists in available items
    EventTriggerItemDropdown? currentValue;
    if (selectedEvent.triggerType != null && selectedEvent.item != null) {
      try {
        currentValue = availableItems.where((EventTriggerItemDropdown item) => item.id == selectedEvent.item!.itemId).firstOrNull;
      } catch (e) {
        currentValue = null;
      }
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: FusionTestKeys.instance.eventtriggerrowheaderitem,
            text: "Item",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "event_trigger_item"),
            child: FusionDropdown<EventTriggerItemDropdown>(
              value: currentValue,
              hint: "Select Item",
              items: availableItems,
              display: (EventTriggerItemDropdown e) => e.name,
              onChanged: (EventTriggerItemDropdown? item) {
                if (item != null) {
                  configEventsViewmodel.updateEventTriggerItem(
                    eventId: eventId,
                    newItem: EventTriggerItem(itemId: item.id),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTypeDropdown extends StatelessWidget {
  final String eventId;
  final ConfigEventsViewmodel cubit;
  const _ActionTypeDropdown({required this.eventId, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = cubit.getEventById(eventId);
    final List<EventActionType> availableActions = cubit.getEventActions(eventId: eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: FusionTestKeys.instance.eventtriggerrowheaderparmandaction,
            text: "Parameter/Action",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_type"),
            child: FusionDropdown<EventActionType>(
              value: selectedEvent.action != null && availableActions.contains(selectedEvent.action) ? selectedEvent.action : null,
              hint: "Select Action",
              items: availableActions,
              display: (EventActionType e) => e.displayName,
              onChanged: (EventActionType? actionType) {
                if (actionType != null) {
                  /// Clear item selection when action type changes to schedule
                  if (actionType.displayName.toLowerCase() == 'schedule') {
                    cubit.updateEventTriggerItem(
                      eventId: eventId,
                      newItem: EventTriggerItem(itemId: ''),
                    );
                  }
                  cubit.updateEventAction(eventId: eventId, newAction: actionType);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionDropdown extends StatelessWidget {
  final String eventId;
  final ConfigEventsViewmodel cubit;
  const _ConditionDropdown({required this.eventId, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = cubit.getEventById(eventId);
    final List<EventConditionType> availableConditions = cubit.getEventConditionTypes(eventId: eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: FusionTestKeys.instance.eventtriggerrowheadercondition,
            text: "Condition",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "event_condition_type"),
            child: FusionDropdown<EventConditionType>(
              value:
                  selectedEvent.condition?.conditionType != null && availableConditions.contains(selectedEvent.condition!.conditionType)
                      ? selectedEvent.condition!.conditionType
                      : null,
              hint: "Select Condition",
              items: availableConditions,
              display: (EventConditionType e) => e.displayName,
              onChanged: (EventConditionType? conditionType) {
                if (conditionType != null) {
                  cubit.updateEventConditionType(eventId: eventId, newConditionType: conditionType);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueColumn extends StatelessWidget {
  final String eventId;
  final ConfigEventsViewmodel cubit;

  const _ValueColumn({
    required this.eventId,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = cubit.getEventById(eventId);
    final EventCondition? condition = selectedEvent.condition;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            semanticId: FusionTestKeys.instance.eventtriggerrowheadervalue,
            text: "Value",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          _buildCondition(context, condition),
        ],
      ),
    );
  }

  Widget _buildCondition(
    BuildContext context,
    EventCondition? condition,
  ) {
    if (condition is StateChangeCondition) {
      return const SizedBox(height: 28);
    } else if (condition is ValueChangeCondition) {
      return _buildRangeSelector(context, condition);
    } else if (condition is ThresholdCondition) {
      return _buildThresholdSlider(context, condition);
    } else {
      return const SizedBox(height: 28);
    }
  }

  /// -------------------- Range Selector --------------------
  Widget _buildRangeSelector(
    BuildContext context,
    ValueChangeCondition condition,
  ) {
    final double minValue = condition.min;
    final double maxValue = condition.max;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
        trackHeight: 1,
        thumbColor: context.colorScheme.primaryWhite,
      ),
      child: RangeSlider(
        values: RangeValues(minValue, maxValue),
        min: 0,
        max: 100,
        activeColor: context.colorScheme.elevation2,
        inactiveColor: context.colorScheme.primaryWhite,
        divisions: 100,
        padding: EdgeInsets.zero,
        labels: RangeLabels(
          minValue.toInt().toString(),
          maxValue.toInt().toString(),
        ),
        onChanged: (RangeValues values) {
          final ValueChangeCondition updatedCondition = condition.copyWith(
            min: values.start,
            max: values.end,
          );

          cubit.updateEventCondition(
            eventId: eventId,
            newCondition: updatedCondition,
          );
        },
      ),
    );
  }

  /// -------------------- Threshold Slider --------------------
  Widget _buildThresholdSlider(
    BuildContext context,
    ThresholdCondition condition,
  ) {
    final double thresholdValue = condition.threshold;

    return Row(
      children: <Widget>[
        Flexible(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
              trackHeight: 1,
              thumbColor: Theme.of(context).colorScheme.primaryWhite,
            ),
            child: Slider(
              value: thresholdValue,
              min: 0,
              max: 100,
              divisions: 100,
              padding: EdgeInsets.zero,
              label: thresholdValue.toStringAsFixed(0),
              activeColor: context.colorScheme.elevation2,
              inactiveColor: context.colorScheme.primaryWhite,
              onChanged: (double value) {
                final ThresholdCondition updatedCondition = condition.copyWith(
                  threshold: value,
                );

                cubit.updateEventCondition(
                  eventId: eventId,
                  newCondition: updatedCondition,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryBlack,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FusionAppText(
            text: thresholdValue.toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
          ),
        ),
      ],
    );
  }
}
