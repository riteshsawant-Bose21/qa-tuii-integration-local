import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshot_value_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_dialog.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'action_drop_down.dart';

class SnapshotActionRowData extends StatefulWidget {
  final SceneActionModel action;
  final int index;

  const SnapshotActionRowData({
    super.key,
    required this.action,
    required this.index,
  });

  @override
  State<SnapshotActionRowData> createState() => _SnapshotActionRowDataState();
}

class _SnapshotActionRowDataState extends State<SnapshotActionRowData> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  List<SceneItemDropdown> get _itemList =>
      widget.action.actionType != null ? _projectViewModel.getActionItemsByType(widget.action.actionType!) : <SceneItemDropdown>[];

  ///
  List<SceneParam> get _paramList {
    final SceneActionModel action = widget.action;
    if (action.actionType == null) return <SceneParam>[];

    if (action.actionType == SceneActionType.snapshot) {
      return _projectViewModel.getParamsByActionTypeAndItem(
        actionType: action.actionType!,
        item: SceneItem(itemId: ''),
      );
    }

    return action.item != null
        ? _projectViewModel.getParamsByActionTypeAndItem(
          actionType: action.actionType!,
          item: action.item!,
        )
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
      _projectViewModel.updateSceneActionParam(actionId: widget.action.id, param: selected);
      setState(() {});
    }
  }

  void _updateActionValue(SceneValue selected) {
    _projectViewModel.updateSceneActionValue(actionId: widget.action.id, value: selected);
  }

  void _deleteAction() {
    showDialog(
      context: context,
      builder:
          (_) => FusionDialog(
            title: 'Delete Action?',
            description: "This will remove action from the Action list.",
            primaryButtonLabel: 'Delete',
            secondaryButtonLabel: 'Cancel',
            onSecondaryPressed: () => Navigator.of(context).pop(),
            onPrimaryPressed: () {
              _projectViewModel.removeSceneAction(actionId: widget.action.id);
              FusionToast.success(context, message: "Action deleted successfully");
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _duplicateAction() {
    _projectViewModel.duplicateSceneAction(actionId: widget.action.id);
    FusionToast.success(context, message: "Action duplicated successfully");
  }

  @override
  Widget build(BuildContext context) {
    final SceneActionModel action = widget.action;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<SceneItemDropdown> itemList = _itemList;
    final List<SceneParam> paramList = _paramList;
    final bool isItemEnabled = action.actionType == null || itemList.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.white,
        border: Border(bottom: BorderSide(color: colorScheme.grey)),
      ),
      child: Row(
        spacing: 12,
        children: <Widget>[
          _buildDragHandle(),
          _buildActionTypeDropdown(action),
          _buildItemDropdown(action, itemList, isItemEnabled),
          _buildParamDropdown(action, paramList),
          _buildValueWidget(action),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return ReorderableDragStartListener(
      index: widget.index,
      child: SizedBox(
        width: 30,
        child: Opacity(
          opacity: 0.4,
          child: Icon(Icons.drag_handle, size: 16, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildActionTypeDropdown(SceneActionModel action) {
    final bool isInSceneSet = _projectViewModel.getSceneSetForSnapshot(snapshotId: _projectViewModel.selectedSnapshotId!) != null;
    return Expanded(
      child: FusionDropdown<SceneActionType>(
        value: action.actionType,
        hint: "Select Action Type",
        items: _projectViewModel.getSceneActionTypes(isFromSnapshot: !isInSceneSet),
        display: (SceneActionType e) => e.displayName,
        onChanged: _updateActionType,
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
      child: FusionDropdown<SceneItemDropdown>(
        value: selected,
        items: itemList,
        hint: hint,
        display: (SceneItemDropdown e) => e.name,
        isEnabled: isEnabled,
        onChanged: isEnabled ? _updateActionItem : null,
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
      child: FusionDropdown<SceneParam>(
        hint: "Select Parameter",
        value: selected,
        items: paramList,
        display: (SceneParam e) => e.label,
        onChanged: _updateActionParam,
      ),
    );
  }

  Widget _buildValueWidget(SceneActionModel action) {
    if (action.param == null) return const Expanded(child: SizedBox.shrink());

    return Expanded(
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
          _updateActionValue(val);
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          GestureDetector(
            onTap: _deleteAction,
            child: const FusionImage.asset(
              Assets.deleteIcon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _duplicateAction,
            child: const FusionImage.asset(
              Assets.duplicateIcon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
