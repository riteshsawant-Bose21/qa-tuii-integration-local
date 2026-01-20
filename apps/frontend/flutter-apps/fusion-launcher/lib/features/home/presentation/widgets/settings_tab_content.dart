import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

enum FusionLanguages {
  english;

  static FusionLanguages? fromString(String value) {
    try {
      return FusionLanguages.values.firstWhere((FusionLanguages element) => element.name == value);
    } catch (e) {
      return null;
    }
  }
}

enum AppStartupBehavior {
  openLastProject("Open Last Project"),
  openHomePage("Open Home Page");

  const AppStartupBehavior(this.title);
  final String title;
}

enum NotificationPreference {
  inAppAlerts("In-app Alerts");

  const NotificationPreference(this.title);
  final String title;
}

class SettingsTabContent extends StatefulWidget {
  const SettingsTabContent({super.key});

  @override
  State<SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<SettingsTabContent> {
  FusionLanguages _selectedLanguage = FusionLanguages.english;
  final ThemeMode _selectedThemeMode = ThemeMode.system;
  AppStartupBehavior _selectedAppStartupBehavior = AppStartupBehavior.openLastProject;
  NotificationPreference _selectedNotificationPreference = NotificationPreference.inAppAlerts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SecionNameWidget(text: "Language & Apperance"),
          const SizedBox(height: 8),

          // =======================================
          //   Language Section
          // =======================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(
              text: "Language",
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.surfaceDim,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FusionDarkDropdown<FusionLanguages>(
                  selectedValue: _selectedLanguage,
                  onChanged: (FusionLanguages? value) {
                    if (value == null) return;
                    setState(() => _selectedLanguage = value);
                  },
                  labelBuilder: (FusionLanguages item) => item.name[0].toUpperCase() + item.name.substring(1),
                  items: FusionLanguages.values,
                ),
              ),
              const Spacer(),
            ],
          ),

          // =======================================
          //   Theme Section
          // =======================================
          // const SizedBox(height: 16),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: FusionAppText(
          //     text: "Theme",
          //     style: context.textTheme.labelMedium?.copyWith(
          //       color: context.colorScheme.surfaceDim,
          //     ),
          //   ),
          // ),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 8),
          //   child: RadioGroup<ThemeMode>(
          //     groupValue: _selectedThemeMode,
          //     onChanged: (ThemeMode? value) {
          //       if (value == null) return;
          //       setState(() => _selectedThemeMode = value);
          //     },
          //     child: Row(
          //       spacing: 10,
          //       children: <Widget>[
          //         ...ThemeMode.values.map((ThemeMode mode) {
          //           final bool isSelected = _selectedThemeMode == mode;

          //           return Row(
          //             spacing: 4,
          //             children: <Widget>[
          //               Radio<ThemeMode>(
          //                 value: mode,
          //                 activeColor: context.colorScheme.onSurface,
          //                 overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          //                 backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          //                 fillColor: WidgetStatePropertyAll<Color>(
          //                   context.colorScheme.onSurface.withValues(
          //                     alpha: isSelected ? 0.8 : 0.3,
          //                   ),
          //                 ),
          //               ),
          //               GestureDetector(
          //                 onTap: () => setState(() => _selectedThemeMode = mode),
          //                 child: FusionAppText(
          //                   text: mode.name[0].toUpperCase() + mode.name.substring(1),
          //                   style: context.textTheme.labelLarge?.copyWith(
          //                     color: context.colorScheme.onSurface.withValues(alpha: 0.9),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           );
          //         }),
          //       ],
          //     ),
          //   ),
          // ),
          const SizedBox(height: 30),

          // =======================================
          //   Application Behavior Section
          // =======================================
          const _SecionNameWidget(text: "Application Behavior"),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(
              text: "Startup Behavior",
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.surfaceDim,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RadioGroup<AppStartupBehavior>(
              groupValue: _selectedAppStartupBehavior,
              onChanged: (AppStartupBehavior? value) {
                // if (value == null) return;
                // setState(() => _selectedAppStartupBehavior = value);
              },
              child: Column(
                children: <Widget>[
                  ...AppStartupBehavior.values.map((AppStartupBehavior appStartupBehavior) {
                    final bool isSelected = _selectedAppStartupBehavior == appStartupBehavior;

                    return Row(
                      spacing: 4,
                      children: <Widget>[
                        Radio<AppStartupBehavior>(
                          value: appStartupBehavior,
                          activeColor: context.colorScheme.onSurface,
                          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                          focusColor: Colors.transparent,
                          fillColor: WidgetStatePropertyAll<Color>(
                            context.colorScheme.onSurface.withValues(
                              alpha: isSelected ? 0.8 : 0.3,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedAppStartupBehavior = appStartupBehavior),
                          child: FusionAppText(
                            text: appStartupBehavior.title,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // =======================================
          //   Notification Preferences Section
          // =======================================
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(
              text: "Notifications Preferences",
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.surfaceDim,
              ),
            ),
          ),

          // Checkbox and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: <Widget>[
                ...NotificationPreference.values.map((NotificationPreference notificationPreference) {
                  final bool isSelected = _selectedNotificationPreference == notificationPreference;

                  return Row(
                    spacing: 4,
                    children: <Widget>[
                      Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _selectedNotificationPreference = notificationPreference;
                          // setState(() {});
                        },
                        activeColor: context.colorScheme.onSurface.withValues(alpha: 0.8),
                        checkColor: context.colorScheme.surface,
                      ),
                      Flexible(
                        child: FusionAppText(
                          text: notificationPreference.title,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
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
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
