import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Controller Settings section — Screen Mode, Screen Saver, and Sleep Time.
///
/// All state is driven by [ConfigControlLoaded] in the BLoC so each controller
/// has independent, persisted settings.
class ControllerSettingsSection extends StatelessWidget {
  const ControllerSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        final ConfigurationControlViewmodel vm = context.read<ConfigurationControlViewmodel>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PanelSectionHeader(title: 'CONTROLLER SETTINGS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildScreenModeRow(context, state, vm),
                  const SizedBox(height: 16),
                  _buildDivider(context),
                  const SizedBox(height: 16),
                  _buildScreenSaverRow(context, state, vm),
                  const SizedBox(height: 16),
                  _buildDivider(context),
                  const SizedBox(height: 16),
                  _buildSleepTimeRow(context, state, vm),
                  const SizedBox(height: 16),
                  _buildDivider(context),
                  const SizedBox(height: 16),
                  _buildWakeFunction(context, state, vm),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight);
  }

  // ─── Screen Mode ─────────────────────────────────────────────────────────────

  Widget _buildScreenModeRow(
    BuildContext context,
    ConfigControlLoaded state,
    ConfigurationControlViewmodel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'SCREEN MODE',
          style: Theme.of(context).textTheme.l1Regular.withColor(
            context.colorScheme.textBody,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _buildRadioOption<ScreenMode>(
              context: context,
              label: 'Light',
              value: ScreenMode.light,
              groupValue: state.screenMode,
              onChanged: (ScreenMode? v) {
                if (v != null) vm.setScreenMode(v);
              },
            ),
            const SizedBox(width: 32),
            _buildRadioOption<ScreenMode>(
              context: context,
              label: 'Dark',
              value: ScreenMode.dark,
              groupValue: state.screenMode,
              onChanged: (ScreenMode? v) {
                if (v != null) vm.setScreenMode(v);
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Screen Saver ─────────────────────────────────────────────────────────────

  Widget _buildScreenSaverRow(
    BuildContext context,
    ConfigControlLoaded state,
    ConfigurationControlViewmodel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'SCREEN SAVER',
          style: Theme.of(context).textTheme.l1Regular.withColor(
            context.colorScheme.textBody,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 32,
          runSpacing: 8,
          children:
              ScreenSaverOption.values
                  .map(
                    (ScreenSaverOption option) => _buildRadioOption<ScreenSaverOption>(
                      context: context,
                      label: option.label,
                      value: option,
                      groupValue: state.screenSaver,
                      onChanged: (ScreenSaverOption? v) {
                        if (v != null) vm.setScreenSaver(v);
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  // ─── Screen Sleep Time ────────────────────────────────────────────────────────

  static const int _minSleep = 5;
  static const int _maxSleep = 300;

  Widget _buildSleepTimeRow(
    BuildContext context,
    ConfigControlLoaded state,
    ConfigurationControlViewmodel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'SCREEN SLEEP TIME AFTER',
          style: Theme.of(context).textTheme.l1Regular.withColor(
            context.colorScheme.textBody,
          ),
        ),
        const SizedBox(height: 2),
        FusionAppText(
          text: 'Note: Enter the time in seconds, allowed range $_minSleep-$_maxSleep seconds.',
          style: Theme.of(context).textTheme.l2Regular.withColor(
            context.colorScheme.textBody,
          ),
        ),
        const SizedBox(height: 16),
        _buildSleepDropdown(context, state, vm),
      ],
    );
  }

  Widget _buildWakeFunction(
    BuildContext context,
    ConfigControlLoaded state,
    ConfigurationControlViewmodel vm,
  ) {
    final List<WakeFunctionOption> options = WakeFunctionOption.values;
    final List<Zone> zones = state.zones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'UPON WAKE FUNCTION',
          style: Theme.of(context).textTheme.l1Regular.withColor(
            context.colorScheme.textBody,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            ...options.map((WakeFunctionOption option) {
              final bool isZone = option == WakeFunctionOption.zone;
              return Row(
                children: <Widget>[
                  _buildRadioOption<WakeFunctionOption>(
                    context: context,
                    label: option.label,
                    value: option,
                    groupValue: state.wakeFunction,
                    onChanged: (WakeFunctionOption? v) {
                      if (v != null) vm.setWakeFunction(v);
                    },
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  if (isZone)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 160,
                        child: FusionNeumorphicDropdown<String>(
                          width: 172,
                          color: context.colorScheme.elevation2,
                          value: state.wakeZoneId,
                          hintText: 'Select zone',
                          items: zones.map((Zone z) => z.id).toList(),
                          itemLabelBuilder: (String id) => zones.firstWhere((Zone z) => z.id == id).name,
                          onChanged: (String v) {
                            if (state.wakeFunction == WakeFunctionOption.zone) {
                              vm.setWakeZone(v);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          height: 28,
                          matchChildWidth: true,
                        ),
                      ),
                    ),
                  const SizedBox(width: 32),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildSleepDropdown(
    BuildContext context,
    ConfigControlLoaded state,
    ConfigurationControlViewmodel vm,
  ) {
    final List<int> values = List<int>.generate(
      _maxSleep - _minSleep + 1,
      (int i) => _minSleep + i,
    );

    return FusionNeumorphicDropdown<int>(
      value: state.sleepTime,
      height: 38,
      width: 120,
      borderRadius: BorderRadius.circular(8),
      hintText: 'Select',
      items: values,
      matchChildWidth: true,
      itemLabelBuilder: (int v) => '$v sec',
      itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      onChanged: (int v) => vm.setSleepTime(v),
    );
  }

  // ─── Shared radio option ──────────────────────────────────────────────────────

  Widget _buildRadioOption<T>({
    required BuildContext context,
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final bool isSelected = value == groupValue;
    final Color activeColor = context.colorScheme.primary;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FusionCheckbox(
            semanticId: '',
            onChanged: () => onChanged(value),
            value: isSelected,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 6),
          FusionAppText(
            text: label,
            style: Theme.of(context).textTheme.l1Regular.withColor(
              isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// end of file
