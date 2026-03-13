import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_tab_switcher.dart';
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
      semantic: 'Processing',
    ),
    ConfigurationMenuMode.snapshots: TabConfig(
      assetsName: Assets.presetsIcon,
      label: 'Snapshots',
      semantic: 'Snapshots',
    ),
    ConfigurationMenuMode.events: TabConfig(
      assetsName: Assets.eventsIcon,
      label: 'Events',
      semantic: 'Events',
    ),
    ConfigurationMenuMode.gpio: TabConfig(
      assetsName: Assets.gpioIcon,
      label: 'GPIO',
      semantic: 'GPIO',
    ),
    ConfigurationMenuMode.scheduling: TabConfig(
      assetsName: Assets.schedulingIcon,
      label: 'Scheduling',
      semantic: 'Scheduling',
    ),

    ConfigurationMenuMode.mediaFiles: TabConfig(
      assetsName: Assets.playIcon,
      label: 'Media Files',
      semantic: 'Media Files',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        FusionTestKeys.instance.configurationTabSwitcher,
      ),
      label: tabConfigs[widget.selectedMode]?.semantic ?? '',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),

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
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.button,
                        '${FusionTestKeys.instance.configurationTabSwitcherItem}_${config.semantic}_option',
                      ),
                      label: widget.selectedMode.name.toString(),
                      selected: isSelected,

                      child: Container(
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.only(
                          right: 8,
                          left: 8,
                          top: 4,
                          bottom: 4,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? context.colorScheme.elevation3
                                  : isHovered
                                  ? context.colorScheme.elevation2
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? context.colorScheme.elevation5 : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SemanticHelper.image(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.icon,
                                FusionTestKeys.instance.configureTabIcon,
                              ),
                              child: FusionImage.asset(
                                config.assetsName,
                                width: 24,
                                height: 24,
                                assetColor: context.colorScheme.primaryWhite,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SemanticHelper.staticText(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.text,
                                '${FusionTestKeys.instance.configureTabtxt}_${config.semantic}',
                              ),
                              child: FusionAppText(
                                text: config.label,
                                maxLine: 1,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? context.colorScheme.primaryWhite
                                          : isHovered
                                          ? context.colorScheme.onSurface.withOpacity(0.9)
                                          : context.colorScheme.onSurface.withOpacity(0.7),
                                ),
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
      ),
    );
  }
}

/// Helper class for tab configuration
class TabConfig {
  final String assetsName;
  final String label;
  final String semantic;
  TabConfig({
    required this.assetsName,
    required this.semantic,
    required this.label,
  });
}
