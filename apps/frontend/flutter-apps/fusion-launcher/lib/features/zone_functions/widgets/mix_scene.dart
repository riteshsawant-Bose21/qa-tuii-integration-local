import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
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
  ValueNotifier<bool> isNewMixSceneNameNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    mixSceneNameController.addListener(() {
      final String trimmedText = mixSceneNameController.text.trim();

      if (trimmedText != widget.selectedMixSceneName) {
        isNewMixSceneNameNotifier.value = true;
      } else {
        isNewMixSceneNameNotifier.value = false;
      }
    });

    mixSceneNameController.text = widget.selectedMixSceneName ?? "";
  }

  @override
  void dispose() {
    mixSceneNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MixScenes oldWidget) {
    if (widget.selectedMixSceneName != oldWidget.selectedMixSceneName) {
      mixSceneNameController.text = widget.selectedMixSceneName ?? "";
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final List<Source> sources = serviceLocator<ProjectViewModel>().getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneId);

    if (sources.isEmpty) return const SizedBox.shrink();

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "mix_scenes_container"),
      child: SizedBox(
        width: 150,
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: FusionAppText(
                text: "MIX SCENES",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Divider(color: context.colorScheme.strokeLight, height: 0),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: NeumorphicPopupButton(
                controller: mixSceneNameController,
                options: widget.mixScenes,
                onSelect: widget.onMixSceneSelect,
                height: 32,
                borderRadius: 8,
              ),
            ),

            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: isNewMixSceneNameNotifier,
              builder: (BuildContext context, bool isNewMixSceneName, Widget? child) {
                return FusionNeumorphicButton(
                  text: isNewMixSceneName ? "STORE" : "UPDATE",
                  width: 94,
                  height: 32,
                  borderRadius: 8,
                  color: context.colorScheme.elevation2,
                  onTap: () {
                    widget.onStoreTap(
                      mixSceneNameController.text.trim(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<bool>(
              valueListenable: isNewMixSceneNameNotifier,
              builder: (BuildContext context, bool isNewMixSceneName, Widget? child) {
                return FusionNeumorphicButton(
                  text: "DELETE",
                  width: 94,
                  height: 32,
                  borderRadius: 8,
                  color: context.colorScheme.elevation2,
                  textStyle: context.textTheme.bodyMedium!.copyWith(
                    color:
                        isNewMixSceneName ? context.colorScheme.primaryWhite.withValues(alpha: 0.4) : context.colorScheme.primaryWhite.withValues(alpha: 0.87),
                  ),
                  onTap: widget.onDeleteTap,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
