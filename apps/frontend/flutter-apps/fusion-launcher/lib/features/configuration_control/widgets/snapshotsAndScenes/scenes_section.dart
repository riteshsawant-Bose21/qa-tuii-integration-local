import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ScenesSection extends StatelessWidget {
  final ConfigControlLoaded state;
  const ScenesSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PanelSectionHeader(title: 'SCENES'),
          Expanded(
            child:
                state.sceneSets.isEmpty
                    ? Center(
                      child: FusionAppText(
                        text: 'No scenes available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.sceneSets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final SceneSetModel sceneSet = state.sceneSets[index];
                        final bool isChecked = state.selectedSceneSetIds.contains(sceneSet.id);
                        return _SceneSetItem(
                          sceneSet: sceneSet,
                          isChecked: isChecked,
                          // Checkbox tap → toggles PAGES-panel membership only
                          onToggle: () => context.read<ConfigurationControlViewmodel>().toggleSceneSetSelection(sceneSet.id),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _SceneSetItem extends StatelessWidget {
  final SceneSetModel sceneSet;
  final bool isChecked;
  final VoidCallback onToggle;

  const _SceneSetItem({
    required this.sceneSet,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FusionCheckbox(isChecked: isChecked),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: sceneSet.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isChecked ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FusionCheckbox extends StatelessWidget {
  final bool isChecked;
  const _FusionCheckbox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isChecked ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
        color: isChecked ? context.colorScheme.primaryColor : Colors.transparent,
      ),
      child: isChecked ? Icon(Icons.check, size: 11, color: context.colorScheme.primaryWhite) : null,
    );
  }
}
