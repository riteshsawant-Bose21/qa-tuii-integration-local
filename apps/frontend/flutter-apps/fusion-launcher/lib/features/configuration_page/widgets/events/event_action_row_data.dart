import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/event_value_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../snapshots/action_drop_down.dart';

class EventActionRowData extends StatefulWidget {
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
  State<EventActionRowData> createState() => _EventActionRowDataState();
}

class _EventActionRowDataState extends State<EventActionRowData> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  List<SceneItemDropdown> get _itemList =>
      widget.action.actionType != null ? _projectViewModel.getActionItemsByType(widget.action.actionType!) : <SceneItemDropdown>[];

  List<SceneParam> get _paramList {
    final SceneActionModel action = widget.action;
    if (action.actionType == null) return <SceneParam>[];

    if (action.actionType == SceneActionType.snapshot) {
      return _projectViewModel.getParamsByActionTypeAndItem(actionType: action.actionType!, item: SceneItem(itemId: ''), eventId: widget.eventId);
    }

    return action.item != null
        ? _projectViewModel.getParamsByActionTypeAndItem(actionType: action.actionType!, item: action.item!, eventId: widget.eventId)
        : <SceneParam>[];
  }

  void _updateActionType(SceneActionType? selected) {
    if (selected != null) {
      _projectViewModel.updateSceneActionType(actionId: widget.action.id, actionType: selected);
    }
  }

  void _updateActionItem(SceneItemDropdown? selected) {
    if (selected != null) {
      _projectViewModel.updateSceneActionItem(
        actionId: widget.action.id,
        item: SceneItem(itemId: selected.id),
      );
    }
  }

  void _updateActionParam(SceneParam? selected) {
    if (selected != null) {
      _projectViewModel.updateSceneActionParam(actionId: widget.action.id, param: selected, eventId: widget.eventId);
    }
  }

  /// update action value for the selected state
  void _updateActionValue(SceneValue updatedSceneValue) {
    _projectViewModel.updateSceneActionValue(actionId: widget.action.id, value: updatedSceneValue);
  }

  void _deleteAction() {
    _projectViewModel.removeActionFromEvent(actionId: widget.action.id, eventId: widget.eventId);
    FusionToast.success(context, message: "Action deleted successfully");
  }

  void _duplicateAction() {
    _projectViewModel.duplicateActionInEvent(eventId: widget.eventId, actionId: widget.action.id);
    FusionToast.success(context, message: "Action duplicated successfully");
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SceneActionModel action = widget.action;
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final List<SceneItemDropdown> itemList = _itemList;
        final List<SceneParam> paramList = _paramList;
        final bool isItemEnabled = action.actionType == null || itemList.isNotEmpty;
        final FusionEvent event = _projectViewModel.getEventById(widget.eventId);

        return SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_row_data_${widget.index}"),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
            color: colorScheme.primaryWhite,
            border: Border(bottom: BorderSide(color: colorScheme.elevation1)),
            ),
            child: Row(
              spacing: context.screenWidth * 0.01,
              children: <Widget>[
                _buildDragHandle(context),
                _buildActionTypeDropdown(action),
                _buildItemDropdown(action, itemList, isItemEnabled),
                _buildParamDropdown(action, paramList),
                (event.condition is! ValueChangeCondition)
                    ? _buildValueWidget(action)
                    : const Expanded(
                      child: Center(
                        child: FusionAppText(text: "--"),
                      ),
                    ),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return ReorderableDragStartListener(
      index: widget.index,
      child: SizedBox(
        width: context.screenWidth * 0.01,
        child: Opacity(
          opacity: 0.4,
          child: Icon(Icons.drag_handle, size: 16, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildActionTypeDropdown(SceneActionModel action) {
    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_type_${widget.index}"),
        child: FusionDropdown<SceneActionType>(
          value: action.actionType,
          hint: "Select Action Type",
          items: _projectViewModel.getSceneActionTypes(isFromSnapshot: false, eventId: widget.eventId),
          display: (SceneActionType e) => e.displayName,
          onChanged: _updateActionType,
        ),
      ),
    );
  }

  Widget _buildItemDropdown(
    SceneActionModel action,
    List<SceneItemDropdown> itemList,
    bool isEnabled,
  ) {
    SceneItemDropdown? selected;
    if (action.item != null && itemList.isNotEmpty) {
      selected = itemList.where((SceneItemDropdown e) => e.id == action.item!.itemId).firstOrNull;
      if (selected == null) action.item = null;
    }

    final String hint =
        action.actionType == null
            ? "Select Action Item"
            : itemList.isEmpty
            ? "No items available"
            : "Select Action Item";

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_item_${widget.index}"),
        child: FusionDropdown<SceneItemDropdown>(
          value: selected,
          items: itemList,
          hint: hint,
          display: (SceneItemDropdown e) => e.name,
          isEnabled: isEnabled,
          onChanged: isEnabled ? _updateActionItem : null,
        ),
      ),
    );
  }

  Widget _buildParamDropdown(SceneActionModel action, List<SceneParam> paramList) {
    SceneParam? selected;
    if (action.param != null && paramList.isNotEmpty) {
      selected =
          paramList
              .where((SceneParam p) => p.label == action.param!.label && p.type == action.param!.type && p.associatedId == action.param!.associatedId)
              .firstOrNull;
    }

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "event_action_param_${widget.index}"),
        child: FusionDropdown<SceneParam>(
          hint: "Select Parameter",
          value: selected,
          items: paramList,
          display: (SceneParam e) => e.label,
          onChanged: _updateActionParam,
        ),
      ),
    );
  }

  Widget _buildValueWidget(SceneActionModel action) {
    if (action.param == null) return const Expanded(child: SizedBox.shrink());
    final FusionEvent event = _projectViewModel.getEventById(widget.eventId);

    // Check if this event has states (2-state events)
    // final bool eventHasStates = event.states != null && event.states!.length == 2;
    final EventStateTypes stateType = event.selectedState?.stateType ?? EventStateTypes.off;
    print("stateType: event.selectedState?.stateType == $stateType");

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
              // hasStates: eventHasStates,
            ),
        onChanged: (SceneValue value) {
          // The EventValueWidget already handles state logic and provides the correct updated value
          _updateActionValue(value);

          // if (action.value != null && action.value!.hasStates) {
          //   print("has state => ${action.value!.hasStates}");
          //   final FusionEvent event = _projectViewModel.getEventById(widget.eventId);
          //   final EventStateTypes stateType = event.selectedState?.stateType ?? EventStateTypes.on;
          //   final SceneValue updatedSceneValue = value.updateStateValue(newValue: value.value ?? '', stateType: stateType);
          //   _updateActionValue(updatedSceneValue);
          // } else {
          //   // final EventStateTypes stateType = event.selectedState?.stateType ?? EventStateTypes.on;
          //   // final SceneValue updatedSceneValue = value.updateStateValue(newValue: value.value ?? '', stateType: stateType);
          //
          //   _updateActionValue(value);
          // }
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: context.screenWidth * 0.046,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "delete_event_action_${widget.index}"),
            child: GestureDetector(
              onTap: _deleteAction,
              child: const FusionImage.asset(
                Assets.deleteIcon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "duplicate_event_action_${widget.index}"),
            child: GestureDetector(
              onTap: _duplicateAction,
              child: const FusionImage.asset(
                Assets.duplicateIcon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
