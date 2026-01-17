import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';

import '../../../../../core/constants/assets_constants.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class ConfigurationTabSwitcher extends StatefulWidget {
  final ConfigurationMenuMode selectedMode;
  final ValueChanged<ConfigurationMenuMode> onModeChanged;

  const ConfigurationTabSwitcher({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  State<ConfigurationTabSwitcher> createState() => _ConfigurationTabSwitcherState();
}

class _ConfigurationTabSwitcherState extends State<ConfigurationTabSwitcher> {
  ConfigurationMenuMode? hoveredMode;

  /// Configuration for each tab
  Map<ConfigurationMenuMode, TabConfig> get tabConfigs => <ConfigurationMenuMode, TabConfig>{
    ConfigurationMenuMode.processing: TabConfig(
      assetsName: Assets.processingIcon,
      label: 'Processing',
    ),
    ConfigurationMenuMode.snapshots: TabConfig(
      assetsName: Assets.presetsIcon,
      label: 'Snapshots',
    ),
    ConfigurationMenuMode.events: TabConfig(
      assetsName: Assets.eventsIcon,
      label: 'Events',
    ),
    ConfigurationMenuMode.gpio: TabConfig(
      assetsName: Assets.gpioIcon,
      label: 'GPIO',
    ),
    ConfigurationMenuMode.scheduling: TabConfig(
      assetsName: Assets.schedulingIcon,
      label: 'Scheduling',
    ),

    ConfigurationMenuMode.mediaFiles: TabConfig(
      assetsName: Assets.playIcon,
      label: 'Media Files',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        // color: colorSche,
        border: Border(
          right: BorderSide(color: context.colorScheme.primaryBlack),
        ),
      ),
      child: Column(
        children:
            ConfigurationMenuMode.values.map((ConfigurationMenuMode mode) {
              final TabConfig config = tabConfigs[mode]!;
              final bool isSelected = widget.selectedMode == mode;
              final bool isHovered = hoveredMode == mode;

              return MouseRegion(
                onEnter: (_) => setState(() => hoveredMode = mode),
                onExit: (_) => setState(() => hoveredMode = null),
                child: SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "configuration_tab_switcher_${mode.name}"),
                  child: GestureDetector(
                    onTap: () => widget.onModeChanged(mode),
                    child: Container(
                      height: 32,

                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.only(right: 16, left: 16, bottom: 4, top: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                              ? context.colorScheme.primaryBlack
                                : isHovered
                              ? context.colorScheme.primaryBlack.withAlpha(50)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          FusionImage.asset(
                            config.assetsName,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 16),
                          FusionAppText(
                            text: config.label,
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color:
                                  isSelected
                                      ? context.colorScheme.onPrimaryContainer
                                      : isHovered
                                      ? context.colorScheme.onSurface.withOpacity(0.9)
                                      : context.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Helper class for tab configuration
class TabConfig {
  final String assetsName;
  final String label;

  TabConfig({
    required this.assetsName,
    required this.label,
  });
}
