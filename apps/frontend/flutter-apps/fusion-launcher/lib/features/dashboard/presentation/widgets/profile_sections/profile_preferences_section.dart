import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/profile_tab_content.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/settings_tab_content.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';
import 'profile_account_secutity_section.dart';

class ProfilePreferencesTab extends StatelessWidget {
  const ProfilePreferencesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();

    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileManager,
      builder: (BuildContext context, UserProfile userProfile, Widget? child) {
        final Notifications notifications = userProfile.notifications;
        final UserProfile profile = userProfileManager.value;

        return Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              text: ProfileTabSections.preferences.title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.surfaceDim,
              ),
            ),
            const SizedBox(height: 10),
            FusionDarkDropdown<MeasurementUnit>(
              selectedValue: MeasurementUnit.fromString(profile.measurementUnit),
              onChanged: (MeasurementUnit value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  measurementUnit: value.name,
                );
              },
              title: "Measurement Units",
              placeholder: "Select",
              items: MeasurementUnit.values,
              labelBuilder: (MeasurementUnit value) => "${value.displayName} (${value.symbol})",
            ),
            const SizedBox(height: 10),
            FusionDarkDropdown<CurrencyType>(
              selectedValue: CurrencyType.fromString(profile.currency),
              onChanged: (CurrencyType value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  currency: value.name,
                );
              },
              title: "Currency",
              placeholder: "Select Currency",
              items: CurrencyType.values,
              labelBuilder: (CurrencyType value) => value.name.toUpperCase(),
            ),
            const SizedBox(height: 10),
            FusionDarkDropdown<FusionLanguages>(
              selectedValue: FusionLanguages.fromString(profile.language),
              onChanged: (FusionLanguages value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  language: value.name,
                );
              },
              title: "Language",
              placeholder: "Select Language",
              items: FusionLanguages.values,
              labelBuilder: (FusionLanguages value) => value.name.toUpperCase(),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: "Notifications",
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.surfaceDim,
                    ),
                  ),
                  // Toggle Switches
                  TinySwitchWithTitle(
                    title: 'Product Updates',
                    value: notifications.productUpdates,
                    onChanged: (bool value) {
                      userProfileManager.value = userProfileManager.value.copyWith(
                        notifications: userProfileManager.value.notifications.copyWith(
                          productUpdates: value,
                        ),
                      );
                    },
                  ),
                  TinySwitchWithTitle(
                    title: 'Project Activity',
                    value: notifications.projectActivity,
                    onChanged: (bool value) {
                      userProfileManager.value = userProfileManager.value.copyWith(
                        notifications: userProfileManager.value.notifications.copyWith(
                          projectActivity: value,
                        ),
                      );
                    },
                  ),
                  TinySwitchWithTitle(
                    title: 'Training & Resources',
                    value: notifications.trainingAndResources,
                    onChanged: (bool value) {
                      userProfileManager.value = userProfileManager.value.copyWith(
                        notifications: userProfileManager.value.notifications.copyWith(
                          trainingAndResources: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            BorderedTextfield(
              initialValue: profile.location,
              label: "Location",
              hintText: "Default Location",
              isEnabled: false,
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: <Widget>[
                Expanded(
                  child: FusionDarkDropdown<CurrencyType>(
                    selectedValue: CurrencyType.fromString(profile.currency),
                    onChanged: (CurrencyType value) {
                      userProfileManager.value = userProfileManager.value.copyWith(
                        currency: value.name,
                      );
                    },
                    title: "Currency",
                    placeholder: "Select Currency",
                    items: CurrencyType.values,
                    labelBuilder: (CurrencyType value) => value.name.toUpperCase(),
                  ),
                ),
                const Expanded(
                  child: BorderedTextfield(
                    // initialValue: profile.discount, // TODO: Implement discount
                    label: "Discount",
                    hintText: "0.0",
                    isEnabled: false,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
