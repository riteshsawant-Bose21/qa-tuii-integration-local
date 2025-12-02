import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

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
      assetsName: Assets.processingIcon,
      label: 'Snapshots',
    ),
    ConfigurationMenuMode.presets: TabConfig(
      assetsName: Assets.presetsIcon,
      label: 'Presets',
    ),
    ConfigurationMenuMode.gpio: TabConfig(
      assetsName: Assets.gpioIcon,
      label: 'GPIO',
    ),
    ConfigurationMenuMode.scheduling: TabConfig(
      assetsName: Assets.schedulingIcon,
      label: 'Scheduling',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        // color: colorSche,
        border: Border(
          right: BorderSide(color: context.colorScheme.dividerColor),
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
                child: GestureDetector(
                  onTap: () => widget.onModeChanged(mode),
                  child: Container(
                    height: 32,

                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(right: 16, left: 16, bottom: 4, top: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? context.colorScheme.greyLight
                              : isHovered
                              ? context.colorScheme.greyLight.withAlpha(50)
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
