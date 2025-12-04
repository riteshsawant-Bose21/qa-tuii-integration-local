import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/value_widget.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

import '../../../../core/constants/assets_constants.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'action_drop_down.dart';

class SnapshotActionRowData extends StatefulWidget {
  final SceneActionModel action;

  const SnapshotActionRowData({
    super.key,
    required this.action,
  });

  @override
  State<SnapshotActionRowData> createState() => _SnapshotActionRowDataState();
}

class _SnapshotActionRowDataState extends State<SnapshotActionRowData> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    final SceneActionModel action = widget.action;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    /// Get item list based on selected action type
    final List<SceneItemDropdown> itemList = action.actionType != null ? _projectViewModel.getActionItemsByType(action.actionType!) : <SceneItemDropdown>[];

    /// Determine if item dropdown should be enabled
    /// Enable by default (when no action type is selected)
    /// Disable only when action type is selected but has no items
    final bool isItemDropdownEnabled = action.actionType == null || itemList.isNotEmpty;

    /// Get param list based on selected action type and item
    /// If no items available, load params directly from action type
    /// This is to handle cases where action type has params but no items (e.g., Global actions)
    final List<SceneParam> paramList =
        action.actionType != null
            ? (itemList.isEmpty
                ? _projectViewModel.getParamsByActionTypeAndItem(action.actionType!, SceneItem(itemId: ''))
                : (action.item != null ? _projectViewModel.getParamsByActionTypeAndItem(action.actionType!, action.item!) : <SceneParam>[]))
            : <SceneParam>[];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.white,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          /// draggable icon
          SizedBox(
            width: 50,
            child: Opacity(
              opacity: 0.4,
              child: Icon(
                Icons.drag_handle,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),

          /// Action Type Dropdown
          Expanded(
            child: FusionDropdown<SceneActionType>(
              value: action.actionType,
              hint: "Select Action Type",
              items: _projectViewModel.getSceneActionTypes(),
              display: (SceneActionType e) => e.displayName,
              onChanged: (SceneActionType? actionType) {
                /// Always clear param and value when action type changes
                action.actionType = actionType;
                action.param = null;
                action.value = null;

                /// Also clear item, and set to first if available
                final List<SceneItemDropdown> newItemList = actionType != null ? _projectViewModel.getActionItemsByType(actionType) : <SceneItemDropdown>[];
                if (newItemList.isNotEmpty) {
                  /// Set to first item in the new list
                  // action.item = SceneItem(itemId: newItemList.first.id);

                  action.item = SceneItem(itemId: "");
                } else {
                  action.item = null;
                }
                if (actionType != null) {
                  _projectViewModel.updateSceneActionType(actionId: action.id, actionType: actionType);
                }
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 12),

          /// Scene Item Dropdown (based on actionType)
          Expanded(
            child: Builder(
              builder: (_) {
                SceneItemDropdown? selectedItem;

                if (action.item != null && itemList.isNotEmpty) {
                  selectedItem = itemList.where((SceneItemDropdown e) => e.id == action.item!.itemId).firstOrNull;

                  /// If item not found in the current list, clear it
                  if (selectedItem == null) {
                    action.item = null;
                  }
                }

                String hintText;
                if (action.actionType == null) {
                  hintText = "Select Action Item";
                } else if (itemList.isEmpty) {
                  hintText = "No items available";
                } else {
                  hintText = "Select Action Item";
                }

                return FusionDropdown<SceneItemDropdown>(
                  value: selectedItem,
                  items: itemList,
                  hint: hintText,
                  display: (SceneItemDropdown e) => e.name,
                  isEnabled: isItemDropdownEnabled,
                  onChanged:
                      isItemDropdownEnabled
                          ? (SceneItemDropdown? selected) {
                            action.item = selected == null ? null : SceneItem(itemId: selected.id);

                            action.param = null;
                            action.value = null;

                            if (action.actionType != null) {
                              _projectViewModel.updateSceneActionType(
                                actionId: action.id,
                                actionType: action.actionType!,
                              );
                            }

                            setState(() {});
                          }
                          : null,
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          /// Param Dropdown (based on actionType and item)
          Expanded(
            child: FusionDropdown<SceneParam>(
              hint: "Select Parameter",
              value:
                  (action.param != null && paramList.isNotEmpty)
                      ? paramList
                          .where(
                            (SceneParam p) => p.label == action.param!.label && p.type == action.param!.type && p.associatedId == action.param!.associatedId,
                          )
                          .firstOrNull
                      : null,
              items: paramList,
              display: (SceneParam e) => e.label,
              onChanged: (SceneParam? actionType) {
                action.param = actionType;

                /// Reset value since param changed and create new SceneValue with correct valueType and label
                if (actionType != null) {
                  action.value = SceneValue(
                    value: null,
                    label: actionType.label,
                    valueType: actionType.valueType,
                  );
                } else {
                  action.value = null;
                }

                if (action.actionType != null) {
                  _projectViewModel.updateSceneActionType(actionId: action.id, actionType: action.actionType!);
                }

                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 12),

          /// Value Widget (based on param's valueType)
          Expanded(
            child:
                action.param != null
                    ? ValueWidgetForRow(
                      actionId: action.id,
                      value:
                          action.value ??
                          SceneValue(
                            value: null,
                            label: action.param!.label,
                            valueType: action.param!.valueType,
                          ),
                      onChanged: (SceneValue newVal) {
                        action.value = newVal;
                        // Update in ViewModel
                        _projectViewModel.updateSceneActionValue(
                          actionId: action.id,
                          value: newVal,
                        );
                        setState(() {});
                      },
                    )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(width: 18),

          /// Delete Action Button
          SizedBox(
            width: 20,
            child:
            /// delete action from the scene
            GestureDetector(
              onTap: () {
                _projectViewModel.removeSceneAction(
                  actionId: action.id,
                );
              },
              // fusion image delete icon
              child: const FusionImage.asset(
                Assets.deleteIcon,
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
