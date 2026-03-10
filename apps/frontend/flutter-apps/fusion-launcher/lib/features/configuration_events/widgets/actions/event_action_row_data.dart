import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_state.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/events/event_value_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/widgets/configuration_widgets/action_drop_down.dart' show FusionDropdown;
import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';

class EventActionRowData extends StatelessWidget {
  final SceneActionModel action;
  final int index;
  final String eventId;

  const EventActionRowData({
    super.key,
    required this.action,
    required this.index,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigEventActionsViewmodel, ConfigEventActionsState>(
      builder: (BuildContext context, ConfigEventActionsState state) {
        // Get the latest action data from state
        final SceneActionModel? currentAction = state.getActionById(action.id);
        if (currentAction == null) {
          return const SizedBox.shrink();
        }

        return _EventActionRowContent(
          action: currentAction,
          index: index,
          eventId: eventId,
        );
      },
    );
  }
}

class _EventActionRowContent extends StatelessWidget {
  final SceneActionModel action;
  final int index;
  final String eventId;

  const _EventActionRowContent({
    required this.action,
    required this.index,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final ConfigEventActionsViewmodel cubit = context.read<ConfigEventActionsViewmodel>();
    final ConfigEventsViewmodel configEventsViewmodel = context.read<ConfigEventsViewmodel>();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<SceneItemDropdown> itemList = _getItemList(cubit);
    final List<SceneParam> paramList = _getParamList(cubit);
    final bool isItemEnabled = action.actionType == null || itemList.isNotEmpty;
    final FusionEvent event = configEventsViewmodel.getEventById(eventId);

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_row_data_$index"),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primaryBlack,
          border: Border(bottom: BorderSide(color: colorScheme.elevation1)),
        ),
        child: Row(
          spacing: context.screenWidth * 0.01,
          children: <Widget>[
            _buildDragHandle(context),
            _buildActionTypeDropdown(context, cubit),
            _buildItemDropdown(context, cubit, itemList, isItemEnabled),
            _buildParamDropdown(context, cubit, paramList),
            (event.condition is! ValueChangeCondition)
                ? _buildValueWidget(context, cubit, configEventsViewmodel)
                : const Expanded(
                  child: Center(
                    child: FusionAppText(text: "--"),
                  ),
                ),
            _buildActionButtons(context, cubit),
          ],
        ),
      ),
    );
  }

  List<SceneItemDropdown> _getItemList(ConfigEventActionsViewmodel cubit) {
    return action.actionType != null ? cubit.getActionItemsByType(action.actionType!) : <SceneItemDropdown>[];
  }

  List<SceneParam> _getParamList(ConfigEventActionsViewmodel cubit) {
    if (action.actionType == null) return <SceneParam>[];

    if (action.actionType == SceneActionType.snapshot) {
      return cubit.getParamsByActionTypeAndItem(
        actionType: action.actionType!,
        item: SceneItem(itemId: ''),
        eventId: eventId,
      );
    }

    return action.item != null
        ? cubit.getParamsByActionTypeAndItem(
          actionType: action.actionType!,
          item: action.item!,
          eventId: eventId,
        )
        : <SceneParam>[];
  }

  Widget _buildDragHandle(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: SizedBox(
        width: context.screenWidth * 0.01,
        child: Opacity(
          opacity: 0.4,
          child: Icon(Icons.drag_indicator, size: 16, color: context.colorScheme.iconWhite),
        ),
      ),
    );
  }

  Widget _buildActionTypeDropdown(BuildContext context, ConfigEventActionsViewmodel cubit) {
    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_type_$index"),
        child: FusionDropdown<SceneActionType>(
          value: action.actionType,
          hint: "Select Action Type",
          items: cubit.getSceneActionTypes(isFromSnapshot: false, eventId: eventId),
          display: (SceneActionType e) => e.displayName,
          onChanged: (SceneActionType? selected) {
            if (selected != null) {
              cubit.updateActionType(actionId: action.id, actionType: selected);
            }
          },
        ),
      ),
    );
  }

  Widget _buildItemDropdown(
    BuildContext context,
    ConfigEventActionsViewmodel cubit,
    List<SceneItemDropdown> itemList,
    bool isEnabled,
  ) {
    SceneItemDropdown? selected;
    if (action.item != null && itemList.isNotEmpty) {
      selected = itemList.where((SceneItemDropdown e) => e.id == action.item!.itemId).firstOrNull;
    }

    final String hint =
        action.actionType == null
            ? "Select Action Item"
            : itemList.isEmpty
            ? "No items available"
            : "Select Action Item";

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_item_$index"),
        child: FusionDropdown<SceneItemDropdown>(
          value: selected,
          items: itemList,
          hint: hint,
          display: (SceneItemDropdown e) => e.name,
          isEnabled: isEnabled,
          onChanged:
              isEnabled
                  ? (SceneItemDropdown? selected) {
                    if (selected != null) {
                      cubit.updateActionItem(
                        actionId: action.id,
                        item: SceneItem(itemId: selected.id),
                      );
                    }
                  }
                  : null,
        ),
      ),
    );
  }

  Widget _buildParamDropdown(BuildContext context, ConfigEventActionsViewmodel cubit, List<SceneParam> paramList) {
    SceneParam? selected;
    if (action.param != null && paramList.isNotEmpty) {
      selected =
          paramList
              .where((SceneParam p) => p.label == action.param!.label && p.type == action.param!.type && p.associatedId == action.param!.associatedId)
              .firstOrNull;
    }

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_param_$index"),
        child: FusionDropdown<SceneParam>(
          hint: "Select Parameter",
          value: selected,
          items: paramList,
          display: (SceneParam e) => e.label,
          onChanged: (SceneParam? selected) {
            if (selected != null) {
              cubit.updateActionParam(actionId: action.id, param: selected, eventId: eventId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildValueWidget(BuildContext context, ConfigEventActionsViewmodel cubit, ConfigEventsViewmodel configEventsViewmodel) {
    if (action.param == null) return const Expanded(child: SizedBox.shrink());
    final FusionEvent event = configEventsViewmodel.getEventById(eventId);
    final EventStateTypes stateType = event.selectedState?.stateType ?? EventStateTypes.off;

    return Expanded(
      child: EventValueWidget(
        key: ValueKey<String>(action.id),
        actionId: action.id,
        stateType: stateType,
        value:
            action.value ??
            SceneValue(
              value: null,
              label: action.param!.label,
              valueType: action.param!.valueType,
            ),
        onChanged: (SceneValue value) {
          cubit.updateActionValue(actionId: action.id, value: value);
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ConfigEventActionsViewmodel cubit) {
    return SizedBox(
      width: context.screenWidth * 0.046,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_event_action_$index"),
            child: GestureDetector(
              onTap: () {
                cubit.deleteAction(actionId: action.id);
                FusionToast.success(context, message: "Action deleted successfully");
              },
              child: FusionImage.asset(
                Assets.deleteIcon,
                width: 20,
                height: 20,
                assetColor: context.colorScheme.iconWhite,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "duplicate_event_action_$index"),
            child: GestureDetector(
              onTap: () {
                cubit.duplicateAction(actionId: action.id);
                FusionToast.success(context, message: "Action duplicated successfully");
              },
              child: FusionImage.asset(
                Assets.duplicateIcon,
                width: 20,
                height: 20,
                assetColor: context.colorScheme.iconWhite,

                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
