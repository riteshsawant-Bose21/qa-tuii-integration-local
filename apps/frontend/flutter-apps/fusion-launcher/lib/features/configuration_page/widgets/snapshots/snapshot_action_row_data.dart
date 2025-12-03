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

    // Move data fetching OUTSIDE BlocBuilder so it updates with setState
    final List<SceneItemDropdown> itemList = action.actionType != null ? _projectViewModel.getActionItemsByType(action.actionType!) : <SceneItemDropdown>[];

    final List<SceneParam> paramList =
        (action.actionType != null && action.item != null) ? _projectViewModel.getParamsByActionTypeAndItem(action.actionType!, action.item!) : <SceneParam>[];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.white,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          /// draggable icon
          SizedBox(
            width: 72,
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
              items: _projectViewModel.getSceneActionTypes(),
              display: (SceneActionType e) => e.name,
              onChanged: (SceneActionType? v) {
                if (v != null) {
                  action.actionType = v;

                  /// Get new item list for the selected action type
                  final List<SceneItemDropdown> newItemList = _projectViewModel.getActionItemsByType(v);
                  print('New Item List: $newItemList');

                  /// Set first item if available, else null
                  if (newItemList.isNotEmpty) {
                    action.item = SceneItem(itemId: newItemList.first.id);
                  } else {
                    action.item = null;
                  }

                  /// Reset param and value since actionType changed
                  action.param = null;
                  action.value = null;
                  setState(() {});
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          /// Scene Item Dropdown (based on actionType)
          Expanded(
            child: FusionDropdown<SceneItemDropdown>(
              value:
                  (action.actionType != null && action.item != null)
                      ? itemList.firstWhere(
                        (SceneItemDropdown e) => e.id == action.item!.itemId,
                        orElse: () => SceneItemDropdown(id: action.item!.itemId, name: action.item!.itemId),
                      )
                      : null,
              items: itemList,
              display: (SceneItemDropdown e) => e.name,
              onChanged: (SceneItemDropdown? v) {
                action.item = v == null ? null : SceneItem(itemId: v.id);
                // Reset param and value since item changed
                action.param = null;
                action.value = null;
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 12),

          /// Param Dropdown (based on actionType and item)
          Expanded(
            child: FusionDropdown<SceneParam>(
              value: action.param,
              items: paramList,
              display: (SceneParam e) => e.label,
              onChanged: (SceneParam? v) {
                action.param = v;
                // Reset value since param changed
                action.value = null;
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
                      value:
                          action.value ??
                          SceneValue(
                            value: null,
                            label: '',
                            // valueType: action.param!.valueType,
                            valueType: SceneParamValueType.textInput,
                          ),
                      onChanged: (SceneValue newVal) {
                        action.value = newVal;
                        setState(() {});
                      },
                    )
                    : const SizedBox.shrink(),
          ),

          SizedBox(
            // color: Colors.red,
            width: 20,
            child:
            // delete icon
            GestureDetector(
              onTap: () {
                // // Notify parent to delete this action
                // _projectViewModel.deleteSceneAction(action);
                // widget.onChanged();
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
