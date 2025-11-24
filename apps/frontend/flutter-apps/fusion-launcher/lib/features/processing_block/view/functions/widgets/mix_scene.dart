import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../common/neumorphic_button.dart';
import 'neumorphic_popup_button.dart';

class MixScenes extends StatefulWidget {
  final String? selectedMixSceneName;
  final String zoneId;
  final ValueChanged<String> onStoreTap;
  final VoidCallback onDeleteTap;
  final List<String> mixScenes;
  final ValueChanged<String> onMixSceneSelect;

  const MixScenes({
    super.key,
    required this.selectedMixSceneName,
    required this.zoneId,
    required this.onStoreTap,
    required this.onDeleteTap,
    required this.mixScenes,
    required this.onMixSceneSelect,
  });

  @override
  State<MixScenes> createState() => _MixScenesState();
}

class _MixScenesState extends State<MixScenes> {
  final TextEditingController mixSceneNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedMixSceneName != null) {
      mixSceneNameController.text = widget.selectedMixSceneName!;
    }
  }

  @override
  void dispose() {
    mixSceneNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MixScenes oldWidget) {
    if (widget.selectedMixSceneName != oldWidget.selectedMixSceneName) {
      mixSceneNameController.text = widget.selectedMixSceneName!;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final List<Source> sources = context.watch<ProjectViewModel>().getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneId);

    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 150,
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: <Widget>[
          Container(
            height: 28,
            color: const Color(0xFFF5F5F5),
            alignment: Alignment.center,
            child: FusionAppText(
              text: "MIX SCENES",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const Divider(color: Colors.black12, height: 0),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: NeumorphicPopupButton(
              controller: mixSceneNameController,
              options: widget.mixScenes,
              onSelect: widget.onMixSceneSelect,
              height: 28,
              borderRadius: 8,
            ),
          ),

          const SizedBox(height: 20),
          NeumorphicButton(
            text: "STORE",
            width: 72,
            height: 28,
            borderRadius: 8,
            onTap: () {
              widget.onStoreTap(
                mixSceneNameController.text.trim(),
              );
            },
          ),
          const SizedBox(height: 10),
          NeumorphicButton(
            text: "DELETE",
            width: 72,
            height: 28,
            borderRadius: 8,
            textColor: Colors.black12,
            onTap: widget.onDeleteTap,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
