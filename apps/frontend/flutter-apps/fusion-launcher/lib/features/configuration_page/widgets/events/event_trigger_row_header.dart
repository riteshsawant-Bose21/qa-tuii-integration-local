import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../snapshots/action_drop_down.dart';

class EventTriggerRowHeader extends StatefulWidget {
  final String eventId;

  const EventTriggerRowHeader({super.key, required this.eventId});

  @override
  State<EventTriggerRowHeader> createState() => _EventTriggerRowHeaderState();
}

class _EventTriggerRowHeaderState extends State<EventTriggerRowHeader> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Theme.of(context).colorScheme.grey.withAlpha(40),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 30),
          _TriggerTypeDropdown(eventId: widget.eventId, projectViewModel: _projectViewModel),
          const SizedBox(width: 16),

          _TriggerItemDropdown(
            eventId: widget.eventId,
            projectViewModel: _projectViewModel,
          ),
          const SizedBox(width: 16),

          _ActionTypeDropdown(eventId: widget.eventId, projectViewModel: _projectViewModel),
          const SizedBox(width: 16),

          _ConditionDropdown(eventId: widget.eventId, projectViewModel: _projectViewModel),
          const SizedBox(width: 16),

          _ValueColumn(eventId: widget.eventId, projectViewModel: _projectViewModel),
        ],
      ),
    );
  }
}

class _TriggerTypeDropdown extends StatelessWidget {
  final String eventId;
  final ProjectViewModel projectViewModel;
  const _TriggerTypeDropdown({required this.eventId, required this.projectViewModel});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = projectViewModel.getEventById(eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Trigger Type",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          FusionDropdown<EventTriggerType>(
            value: selectedEvent.triggerType,
            hint: "Select Trigger Type",
            items: projectViewModel.getEventTriggers(),
            display: (EventTriggerType e) => e.displayName,
            onChanged: (EventTriggerType? triggerType) {
              if (triggerType != null) {
                // Clear all dependent values when trigger type changes
                // projectViewModel.clearEventDependentValues(eventId: eventId);
                projectViewModel.updateEventTrigger(eventId: eventId, newTrigger: triggerType);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Item Dropdown
class _TriggerItemDropdown extends StatelessWidget {
  final String eventId;
  final ProjectViewModel projectViewModel;

  const _TriggerItemDropdown({required this.eventId, required this.projectViewModel});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = projectViewModel.getEventById(eventId);
    final List<EventTriggerItemDropdown> availableItems =
        selectedEvent.triggerType != null
            ? projectViewModel.getEventTriggerDropdownItems(triggerType: selectedEvent.triggerType!)
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
            text: "Item",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          FusionDropdown<EventTriggerItemDropdown>(
            value: currentValue,
            hint: "Select Item",
            items: availableItems,
            display: (EventTriggerItemDropdown e) => e.name,
            onChanged: (EventTriggerItemDropdown? item) {
              if (item != null) {
                projectViewModel.updateEventTriggerItem(
                  eventId: eventId,
                  newItem: EventTriggerItem(
                    itemId: item.id,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTypeDropdown extends StatelessWidget {
  final String eventId;
  final ProjectViewModel projectViewModel;
  const _ActionTypeDropdown({required this.eventId, required this.projectViewModel});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = projectViewModel.getEventById(eventId);
    final List<EventActionType> availableActions = projectViewModel.getEventActions(eventId: eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Parameter/Action",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          FusionDropdown<EventActionType>(
            value: selectedEvent.action != null && availableActions.contains(selectedEvent.action) ? selectedEvent.action : null,
            hint: "Select Action",
            items: availableActions,
            display: (EventActionType e) => e.displayName,
            onChanged: (EventActionType? actionType) {
              if (actionType != null) {
                // Clear item selection when action type changes to schedule
                if (actionType.displayName.toLowerCase() == 'schedule') {
                  projectViewModel.updateEventTriggerItem(
                    eventId: eventId,
                    newItem: EventTriggerItem(itemId: ''),
                  );
                }
                projectViewModel.updateEventAction(eventId: eventId, newAction: actionType);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ConditionDropdown extends StatelessWidget {
  final String eventId;
  final ProjectViewModel projectViewModel;
  const _ConditionDropdown({required this.eventId, required this.projectViewModel});

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = projectViewModel.getEventById(eventId);
    final List<EventConditionType> availableConditions = projectViewModel.getEventConditionTypes(eventId: eventId);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Condition",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          FusionDropdown<EventConditionType>(
            value:
                selectedEvent.condition?.conditionType != null && availableConditions.contains(selectedEvent.condition!.conditionType)
                    ? selectedEvent.condition!.conditionType
                    : null,
            hint: "Select Condition",
            items: availableConditions,
            display: (EventConditionType e) => e.displayName,
            onChanged: (EventConditionType? conditionType) {
              if (conditionType != null) {
                projectViewModel.updateEventConditionType(eventId: eventId, newConditionType: conditionType);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ValueColumn extends StatefulWidget {
  final String eventId;
  final ProjectViewModel projectViewModel;

  const _ValueColumn({required this.eventId, required this.projectViewModel});

  @override
  State<_ValueColumn> createState() => _ValueColumnState();
}

class _ValueColumnState extends State<_ValueColumn> {
  double _minValue = 0;
  double _maxValue = 100;
  double _thresholdValue = 50;

  @override
  Widget build(BuildContext context) {
    final FusionEvent selectedEvent = widget.projectViewModel.getEventById(widget.eventId);

    final EventCondition? condition = selectedEvent.condition;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Value",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            maxLine: 1,
          ),
          const SizedBox(height: 8),
          _buildCondition(condition),
        ],
      ),
    );
  }

  Widget _buildCondition(EventCondition? condition) {
    if (condition is StateChangeCondition) {
      return Container(height: 28);
    } else if (condition is ValueChangeCondition) {
      return _buildRangeSelector();
    } else if (condition is ThresholdCondition) {
      return _buildThresholdSlider();
    } else {
      return Container(height: 28);
    }
  }

  Widget _buildRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 4,
            ),
            trackHeight: 2,
            thumbColor: Theme.of(context).colorScheme.black,
            activeTrackColor: Theme.of(context).colorScheme.greyDark,
            inactiveTrackColor: Theme.of(context).colorScheme.grey,
          ),
          child: RangeSlider(
            values: RangeValues(_minValue, _maxValue),
            min: 0,
            max: 100,
            divisions: 100,
            padding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.greyDark,
            inactiveColor: Theme.of(context).colorScheme.grey,
            labels: RangeLabels(
              _minValue.toInt().toString(),
              _maxValue.toInt().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _minValue = values.start;
                _maxValue = values.end;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Threshold Slider
  Widget _buildThresholdSlider() {
    final double currentValue = double.tryParse("50") ?? 50;

    return Row(
      children: <Widget>[
        Flexible(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 4),
              trackHeight: 1,
              thumbColor: Theme.of(context).colorScheme.black,
            ),
            child: Slider(
              value: currentValue,
              padding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.greyDark,
              inactiveColor: Theme.of(context).colorScheme.grey,
              min: 0,
              max: 100,
              divisions: 100,

              label: currentValue.toStringAsFixed(0),
              onChanged: (double value) {
                // final SceneValue updated = value.copyWith(value: v.toString());
                // widget.onChanged(updated);
                setState(() {});
              },
            ),
          ),
        ),

        const SizedBox(width: 16),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.greyLight,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FusionAppText(text: currentValue.toStringAsFixed(0), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
        ),
      ],
    );
  }
}
