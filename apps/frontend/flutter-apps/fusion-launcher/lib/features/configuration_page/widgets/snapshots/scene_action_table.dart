import 'package:flutter/material.dart';
import 'widgets/scene_action_header.dart';
import 'widgets/scene_action_row.dart';
import '../models/scene_action_model.dart';
import '../models/scene_models.dart'; // ← your enums + classes

class SceneActionTable extends StatefulWidget {
  final String sceneId;
  final List<SceneActionModel> actions;

  const SceneActionTable({
    super.key,
    required this.sceneId,
    required this.actions,
  });

  @override
  State<SceneActionTable> createState() => _SceneActionTableState();
}

class _SceneActionTableState extends State<SceneActionTable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SceneActionHeader(),

        const SizedBox(height: 8),

        ...widget.actions.map((action) {
          return SceneActionRow(
            action: action,
            onChanged: () => setState(() {}),
          );
        }).toList(),
      ],
    );
  }
}
