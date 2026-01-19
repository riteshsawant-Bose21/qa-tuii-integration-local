import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/profile_tab_content.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';

class ProfileInformationTab extends StatelessWidget {
  const ProfileInformationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();

    final PersonalInfo personalInfo = userProfileManager.value.personalInfo;
    final Address address = userProfileManager.value.address;
    final Security security = userProfileManager.value.security;

    final String location = userProfileManager.value.location;

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: ProfileTabSections.personalInformation.title,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.surfaceDim,
          ),
        ),
        const SizedBox(height: 10),
        BorderedTextfield(
          initialValue: personalInfo.name,
          label: "Full Name",
          hintText: "e.g. John",
          isEnabled: false,
        ),
        const SizedBox(height: 10),
        Row(
          spacing: 10,
          children: <Widget>[
            Expanded(
              child: BorderedTextfield(
                initialValue: personalInfo.organization,
                label: "Organization",
                hintText: "e.g. Bose Professional",
                isEnabled: false,
              ),
            ),
            Expanded(
              child: BorderedTextfield(
                initialValue: personalInfo.jobTitle,
                label: "Role",
                hintText: "Job Title/Role",
                isEnabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BorderedTextfield(
          initialValue: security.username,
          label: "Email",
          hintText: "e.g. john.doe@example.com",
          isEnabled: false,
        ),
        const SizedBox(height: 10),
        Row(
          spacing: 10,
          children: <Widget>[
            Expanded(
              child: BorderedTextfield(
                initialValue: personalInfo.phone,
                label: "Phone Numner",
                hintText: "e.g. 00-0000-0000",
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
        const SizedBox(height: 10),
        BorderedTextfield(
          initialValue: location,
          label: "Business Address",
          hintText: "Address",
          isEnabled: false,
        ),
      ],
    );
  }
}
