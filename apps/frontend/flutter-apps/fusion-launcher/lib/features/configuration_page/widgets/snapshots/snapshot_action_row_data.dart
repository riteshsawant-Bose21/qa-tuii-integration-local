import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshot_actions_cubit.dart';
import 'package:fusion_launcher/features/configuration_page/cubit/snapshots/snapshot_actions_state.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_value_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../../core/constants/assets_constants.dart';
import 'action_drop_down.dart';

class SnapshotActionRowData extends StatelessWidget {
  final SceneActionModel action;
  final int index;

  const SnapshotActionRowData({
    super.key,
    required this.action,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotActionsCubit, SnapshotActionsState>(
      builder: (BuildContext context, SnapshotActionsState state) {
        // Get the latest action data from state
        final SceneActionModel? currentAction = state.getActionById(action.id);
        if (currentAction == null) {
          return const SizedBox.shrink();
        }

        return _SnapshotActionRowContent(
          action: currentAction,
          index: index,
        );
      },
    );
  }
}

class _SnapshotActionRowContent extends StatelessWidget {
  final SceneActionModel action;
  final int index;

  const _SnapshotActionRowContent({
    required this.action,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final SnapshotActionsCubit cubit = context.read<SnapshotActionsCubit>();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<SceneItemDropdown> itemList = _getItemList(cubit);
    final List<SceneParam> paramList = _getParamList(cubit);
    final bool isItemEnabled = action.actionType == null || itemList.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryBlack,
        border: Border(bottom: BorderSide(color: colorScheme.elevation1)),
      ),
      child: Row(
        spacing: 12,
        children: <Widget>[
          _buildDragHandle(context),
          _buildActionTypeDropdown(context, cubit),
          _buildItemDropdown(context, cubit, itemList, isItemEnabled),
          _buildParamDropdown(context, cubit, paramList),
          _buildValueWidget(context, cubit),
          _buildActionButtons(context, cubit),
        ],
      ),
    );
  }

  List<SceneItemDropdown> _getItemList(SnapshotActionsCubit cubit) {
    return action.actionType != null ? cubit.getActionItemsByType(action.actionType!) : <SceneItemDropdown>[];
  }

  List<SceneParam> _getParamList(SnapshotActionsCubit cubit) {
    if (action.actionType == null) return <SceneParam>[];

    if (action.actionType == SceneActionType.snapshot) {
      return cubit.getParamsByActionTypeAndItem(
        actionType: action.actionType!,
        item: SceneItem(itemId: ''),
      );
    }

    return action.item != null
        ? cubit.getParamsByActionTypeAndItem(
          actionType: action.actionType!,
          item: action.item!,
        )
        : <SceneParam>[];
  }

  Widget _buildDragHandle(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: SizedBox(
        width: 30,
        child: Opacity(
          opacity: 0.4,
          child: Icon(Icons.drag_indicator, size: 16, color: context.colorScheme.iconWhite),
        ),
      ),
    );
  }

  Widget _buildActionTypeDropdown(BuildContext context, SnapshotActionsCubit cubit) {
    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_type_$index"),
        child: FusionDropdown<SceneActionType>(
          value: action.actionType,
          hint: "Select Action Type",
          items: cubit.getSceneActionTypes(isFromSnapshot: true),
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
    SnapshotActionsCubit cubit,
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
        testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_item_$index"),
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

  Widget _buildParamDropdown(BuildContext context, SnapshotActionsCubit cubit, List<SceneParam> paramList) {
    SceneParam? selected;
    if (action.param != null && paramList.isNotEmpty) {
      selected =
          paramList
              .where((SceneParam p) => p.label == action.param!.label && p.type == action.param!.type && p.associatedId == action.param!.associatedId)
              .firstOrNull;
    }

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_param_$index"),
        child: FusionDropdown<SceneParam>(
          hint: "Select Parameter",
          value: selected,
          items: paramList,
          display: (SceneParam e) => e.label,
          onChanged: (SceneParam? selected) {
            if (selected != null) {
              cubit.updateActionParam(actionId: action.id, param: selected);
            }
          },
        ),
      ),
    );
  }

  Widget _buildValueWidget(BuildContext context, SnapshotActionsCubit cubit) {
    if (action.param == null) return const Expanded(child: SizedBox.shrink());

    return Expanded(
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_value_$index"),
        child: SnapshotValueWidget(
          actionId: action.id,
          value:
              action.value ??
              SceneValue(
                value: null,
                label: action.param!.label,
                valueType: action.param!.valueType,
              ),
          onChanged: (SceneValue val) {
            cubit.updateActionValue(actionId: action.id, value: val);
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SnapshotActionsCubit cubit) {
    return SizedBox(
      width: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_delete_$index"),
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
            testId: SemanticHelper.createTestId(SemanticTypes.button, "snapshot_action_duplicate_$index"),
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
