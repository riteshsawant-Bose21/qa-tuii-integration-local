import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/value_widget.dart';
import 'package:fusion_lib/models/project_entities/non_processing/scene_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'action_drop_down.dart';

class SceneActionRow extends StatefulWidget {
  final SceneActionModel action;
  final VoidCallback onChanged;

  const SceneActionRow({
    super.key,
    required this.action,
    required this.onChanged,
  });

  @override
  State<SceneActionRow> createState() => _SceneActionRowState();
}

class _SceneActionRowState extends State<SceneActionRow> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    final SceneActionModel action = widget.action;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionDropdown<SceneActionType>(
              value: action.actionType,
              items: _projectViewModel.getSceneActionTypes(),
              display: (SceneActionType e) => e.name,
              onChanged: (SceneActionType? v) {
                // updateSceneActionType(
                //   actionId: action.id,
                //   actionType: v!,
                // );
                widget.onChanged();
              },
            ),
          ),

          // Expanded(
          //   child: FusionDropdown<SceneItemDropdown>(
          //     value: action.item,
          //     items: _projectViewModel.getActionItemsByType(action.actionType!),
          //     display: (SceneItemDropdown e) => e.name,
          //     onChanged: (SceneItemDropdown? v) {
          //       widget.onChanged();
          //     },
          //   ),
          // ),
          /// Scene Item Dropdown
          Expanded(
            child: FusionDropdown<SceneItemDropdown>(
              value:
                  action.item == null
                      ? null
                      : _projectViewModel
                          .getActionItemsByType(action.actionType!)
                          .firstWhere(
                            (SceneItemDropdown e) => e.id == action.item!.itemId,
                            orElse: () => SceneItemDropdown(id: action.item!.itemId, name: action.item!.itemId),
                          ),
              items: _projectViewModel.getActionItemsByType(action.actionType!),
              display: (SceneItemDropdown e) => e.name,
              onChanged: (SceneItemDropdown? v) {
                final SceneItem? sceneItem = v == null ? null : SceneItem(itemId: v.id);
                // widget.onChanged(sceneItem);
              },
            ),
          ),

          ///  Param widget
          Expanded(
            child: FusionDropdown<SceneParam>(
              value: action.param,
              items: _projectViewModel.getParamsByActionTypeAndItem(action.actionType!, action.item!),
              display: (SceneParam e) => e.label,
              onChanged: (SceneParam? v) {
                // updateSceneActionParam(
                //   actionId: action.id,
                //   param: v!,
                // );
                widget.onChanged();
              },
            ),
          ),

          /// Value widget (auto based on valueType)
          Expanded(
            child: ValueWidgetForRow(
              value:
                  action.value ??
                  SceneValue(
                    value: null,
                    label: '',
                    valueType: SceneParamValueType.dropdownSingle,
                  ),
              onChanged: (SceneValue newVal) {
                // action.value = newVal;
                // widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}
