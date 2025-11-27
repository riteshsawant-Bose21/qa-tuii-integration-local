import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

enum FusionLanguages { english }

class SettingsTabContent extends StatefulWidget {
  const SettingsTabContent({super.key});

  @override
  State<SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<SettingsTabContent> {
  FusionLanguages _selectedLanguage = FusionLanguages.english;
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SecionNameWidget(text: "Language & Apperance"),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(
              text: "Language",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onInverseSurface),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: DropdownButton<FusionLanguages?>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: <DropdownMenuItem<FusionLanguages?>>[
                        ...FusionLanguages.values.map((FusionLanguages lang) {
                          return DropdownMenuItem<FusionLanguages>(
                            value: lang,
                            child: FusionAppText(
                              text: lang.name[0].toUpperCase() + lang.name.substring(1),
                            ),
                          );
                        }),
                      ],
                      underline: const SizedBox(),
                      onChanged: (FusionLanguages? value) {
                        if (value == null) return;
                        setState(() => _selectedLanguage = value);
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(
              text: "Theme",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RadioGroup<ThemeMode>(
              groupValue: _selectedThemeMode,
              onChanged: (ThemeMode? value) {
                if (value == null) return;
                setState(() => _selectedThemeMode = value);
              },
              child: Row(
                spacing: 10,
                children: <Widget>[
                  ...ThemeMode.values.map((ThemeMode mode) {
                    final bool isSelected = _selectedThemeMode == mode;

                    return Row(
                      spacing: 4,
                      children: <Widget>[
                        Radio<ThemeMode>(
                          value: mode,
                          activeColor: Theme.of(context).colorScheme.onSurface,
                        ),
                        FusionAppText(text: mode.name[0].toUpperCase() + mode.name.substring(1)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// section
class _SecionNameWidget extends StatelessWidget {
  final String text;
  const _SecionNameWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
