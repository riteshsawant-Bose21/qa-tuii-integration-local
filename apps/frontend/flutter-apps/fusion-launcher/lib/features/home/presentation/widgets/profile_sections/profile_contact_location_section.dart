// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/profile_tab_content.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';

enum FusionTimeZones {
  IST,
  GMT,
  UTC,
  PST,
  EST;

  // get by string
  static FusionTimeZones? fromString(String value) {
    try {
      return FusionTimeZones.values.firstWhere((FusionTimeZones element) => element.name == value);
    } catch (e) {
      return null;
    }
  }
}

class ProfileContactAndLocationTab extends StatelessWidget {
  const ProfileContactAndLocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();

    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileManager,
      builder: (BuildContext context, UserProfile userProfile, Widget? child) {
        final Address address = userProfile.address;

        return Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              text: ProfileTabSections.contactAndLocation.title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.surfaceDim,
              ),
            ),
            const SizedBox(height: 10),
            FusionDarkDropdown<FusionTimeZones>(
              selectedValue: FusionTimeZones.fromString(address.timezone),
              onChanged: (FusionTimeZones value) {
                // TODO: Implement onChanged to update UserProfileManager
              },
              title: "Time Zone",
              items: FusionTimeZones.values,
              labelBuilder: (FusionTimeZones item) => item.name,
            ),
            const SizedBox(height: 10),
            BorderedTextfield(
              initialValue: address.addressLine1,
              label: "Address Line 1",
              hintText: "e.g. 123, Main Street",
              isEnabled: false,
            ),
            const SizedBox(height: 10),
            BorderedTextfield(
              initialValue: address.addressLine2,
              label: "Address Line 2",
              hintText: "e.g. Apartment, Suite, Unit, Building",
              isEnabled: false,
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: <Widget>[
                Expanded(
                  child: BorderedTextfield(
                    initialValue: address.state,
                    label: "State",
                    hintText: "e.g. California",
                    isEnabled: false,
                  ),
                ),
                Expanded(
                  child: BorderedTextfield(
                    initialValue: address.zipCode,
                    label: "Zip Code",
                    hintText: "000000",
                    isEnabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              spacing: 10,
              children: <Widget>[
                Expanded(
                  child: BorderedTextfield(
                    initialValue: address.country,
                    label: "Country",
                    hintText: "Country",
                    isEnabled: false,
                  ),
                ),
                Expanded(
                  child: BorderedTextfield(
                    initialValue: address.city,
                    label: "City",
                    hintText: "City",
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
