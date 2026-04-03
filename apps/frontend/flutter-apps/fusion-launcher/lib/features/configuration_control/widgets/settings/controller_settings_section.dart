import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Available screen mode options
enum ScreenMode { light, dark }

/// Available screen saver options
enum ScreenSaverOption { dateAndTime, qrCode, homeScreen, blackScreen }

extension ScreenSaverOptionLabel on ScreenSaverOption {
  String get label {
    switch (this) {
      case ScreenSaverOption.dateAndTime:
        return 'Date and time';
      case ScreenSaverOption.qrCode:
        return 'QR Code';
      case ScreenSaverOption.homeScreen:
        return 'Home screen';
      case ScreenSaverOption.blackScreen:
        return 'Black screen';
    }
  }
}

/// Controller Settings section — Screen Mode, Screen Saver, and Sleep Time
class ControllerSettingsSection extends StatefulWidget {
  const ControllerSettingsSection({super.key});

  @override
  State<ControllerSettingsSection> createState() => _ControllerSettingsSectionState();
}

class _ControllerSettingsSectionState extends State<ControllerSettingsSection> {
  ScreenMode _screenMode = ScreenMode.dark;
  ScreenSaverOption _screenSaver = ScreenSaverOption.qrCode;
  int _sleepTime = 30;

  static const int _minSleep = 5;
  static const int _maxSleep = 300;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PanelSectionHeader(title: 'CONTROLLER SETTINGS'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildScreenModeRow(context),
              const SizedBox(height: 16),
              _buildDivider(context),
              const SizedBox(height: 16),
              _buildScreenSaverRow(context),
              const SizedBox(height: 16),
              _buildDivider(context),
              const SizedBox(height: 16),
              _buildSleepTimeRow(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight);
  }

  // ─── Screen Mode ─────────────────────────────────────────────────────────────

  Widget _buildScreenModeRow(BuildContext context) {
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
              groupValue: _screenMode,
              onChanged: (ScreenMode? v) {
                if (v != null) setState(() => _screenMode = v);
              },
            ),
            const SizedBox(width: 32),
            _buildRadioOption<ScreenMode>(
              context: context,
              label: 'Dark',
              value: ScreenMode.dark,
              groupValue: _screenMode,
              onChanged: (ScreenMode? v) {
                if (v != null) setState(() => _screenMode = v);
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Screen Saver ─────────────────────────────────────────────────────────────

  Widget _buildScreenSaverRow(BuildContext context) {
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
                      groupValue: _screenSaver,
                      onChanged: (ScreenSaverOption? v) {
                        if (v != null) setState(() => _screenSaver = v);
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  // ─── Screen Sleep Time ────────────────────────────────────────────────────────

  Widget _buildSleepTimeRow(BuildContext context) {
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
        _buildSleepDropdown(context),
      ],
    );
  }

  Widget _buildSleepDropdown(BuildContext context) {
    final List<int> values = List<int>.generate(
      _maxSleep - _minSleep + 1,
      (int i) => _minSleep + i,
    );

    return FusionNeumorphicDropdown<int>(
      value: _sleepTime,
      height: 38,
      width: 120,
      borderRadius: BorderRadius.circular(8),
      hintText: 'Select',
      items: values,
      matchChildWidth: true,
      itemLabelBuilder: (int v) => '$v sec',

      /// Fixed item height via vertical padding — 8+text+8 ≈ 32 px per row
      itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      /// Cap popup at 200 px so it scrolls instead of growing full-screen
      constraints: const BoxConstraints(maxHeight: 400),
      onChanged: (int v) => setState(() => _sleepTime = v),
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
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : context.colorScheme.elevation4,
                width: 2,
              ),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                      ),
                    )
                    : null,
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
